import EMathicaWorkspaceKit
import EMathicaMathCore
import SwiftUI

struct PlaneCanvasView: View {
    @Environment(\.colorScheme) private var colorScheme

    let canvasState: CanvasState
    let objects: [MathObject]
    let selectedObjectID: UUID?
    let activeToolID: String
    let draftMathObject: DraftMathObject?
    let dispatch: (WorkspaceCommand) -> Void

    @State private var panStartOrigin: CGPoint?
    @State private var pinchStartState: CanvasState?
    @State private var interactionState = PlaneInteractionState()
    @State private var dragIntent: PlaneDragIntent = .none

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                canvasBackground

                PlaneGridRendererView(canvasState: canvasState)

                if canvasState.showAxis {
                    PlaneAxisRendererView(canvasState: canvasState)
                }

                PlaneObjectRendererView(
                    canvasState: canvasState,
                    objects: objects,
                    selectedObjectID: selectedObjectID,
                    draftMathObject: draftMathObject,
                    constructionPreview: interactionState.constructionPreview
                )
            }
            .contentShape(Rectangle())
            .gesture(panGesture(in: proxy.size))
            .simultaneousGesture(zoomGesture(in: proxy.size))
            .simultaneousGesture(tapGesture(in: proxy.size))
            .simultaneousGesture(pointDragGesture(in: proxy.size))
            .simultaneousGesture(constructionPreviewGesture(in: proxy.size))
            .overlay(alignment: .topLeading) {
                constructionHintOverlay
            }
            .onChange(of: activeToolID) { _, _ in
                if let draggingID = interactionState.draggingObjectID {
                    dispatch(.setObjectDragging(id: draggingID, isDragging: false))
                }
                interactionState = PlaneInteractionState()
                dragIntent = .none
                panStartOrigin = nil
            }
        }
    }

    private var canvasBackground: some View {
        let dark = LinearGradient(
            colors: [Color(red: 0.04, green: 0.06, blue: 0.10), Color(red: 0.04, green: 0.08, blue: 0.16)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let light = LinearGradient(
            colors: [Color.white, Color(red: 0.94, green: 0.96, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return (colorScheme == .dark ? dark : light)
    }

    private func panGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .onChanged { value in
                if dragIntent == .none {
                    if activeToolID == "plane.select",
                       let pointID = PlaneHitTestService.hitTestPoint(
                           at: value.startLocation,
                           objects: objects,
                           canvasState: canvasState,
                           canvasSize: size
                       ) {
                        dragIntent = .dragPoint(pointID)
                    } else {
                        dragIntent = .panCanvas
                    }
                }
                guard dragIntent == .panCanvas else { return }
                guard shouldPanCanvas(startLocation: value.startLocation, canvasSize: size) else { return }
                dispatch(.setCanvasInteracting(true))
                if panStartOrigin == nil {
                    panStartOrigin = canvasState.origin
                }
                let start = panStartOrigin ?? canvasState.origin
                let translation = value.translation
                let newOrigin = CGPoint(x: start.x + translation.width, y: start.y + translation.height)
                dispatch(.setCanvasViewport(CanvasState(
                    origin: newOrigin,
                    scale: canvasState.scale,
                    showGrid: canvasState.showGrid,
                    showAxis: canvasState.showAxis,
                    minScale: canvasState.minScale,
                    maxScale: canvasState.maxScale
                )))
            }
            .onEnded { _ in
                panStartOrigin = nil
                dragIntent = .none
                dispatch(.setCanvasInteracting(false))
            }
    }

    private func shouldPanCanvas(startLocation: CGPoint, canvasSize: CGSize) -> Bool {
        if activeToolID == "plane.pan" {
            return true
        }
        if activeToolID == "plane.select" {
            return hitTestObject(at: startLocation, canvasSize: canvasSize) == nil
        }
        return false
    }

    private func zoomGesture(in size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { magnification in
                dispatch(.setCanvasInteracting(true))
                if pinchStartState == nil {
                    pinchStartState = canvasState
                }
                guard let start = pinchStartState else { return }
                let anchor = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                let oldScale = start.scale
                let newScale = CanvasState.clampScale(oldScale * Double(magnification), min: start.minScale, max: start.maxScale)

                let anchorWorld = screenToWorld(anchor, canvasSize: size, originOffset: start.origin, scale: oldScale)
                let newOriginOffset = originOffsetKeepingAnchor(anchorScreen: anchor, anchorWorld: anchorWorld, canvasSize: size, scale: newScale)

                dispatch(.setCanvasViewport(CanvasState(
                    origin: newOriginOffset,
                    scale: newScale,
                    showGrid: start.showGrid,
                    showAxis: start.showAxis,
                    minScale: start.minScale,
                    maxScale: start.maxScale
                )))
            }
            .onEnded { _ in
                pinchStartState = nil
                dispatch(.setCanvasInteracting(false))
            }
    }

    private func screenToWorld(_ screen: CGPoint, canvasSize: CGSize, originOffset: CGPoint, scale: Double) -> WorldPoint {
        let originScreen = CGPoint(x: canvasSize.width * 0.5 + originOffset.x, y: canvasSize.height * 0.5 + originOffset.y)
        let worldX = Double((screen.x - originScreen.x) / CGFloat(scale))
        let worldY = Double((originScreen.y - screen.y) / CGFloat(scale))
        return WorldPoint(x: worldX, y: worldY)
    }

    private func worldToScreen(_ world: WorldPoint, canvasSize: CGSize, originOffset: CGPoint, scale: Double) -> CGPoint {
        let originScreen = CGPoint(x: canvasSize.width * 0.5 + originOffset.x, y: canvasSize.height * 0.5 + originOffset.y)
        return CGPoint(
            x: originScreen.x + CGFloat(world.x) * CGFloat(scale),
            y: originScreen.y - CGFloat(world.y) * CGFloat(scale)
        )
    }

    private func originOffsetKeepingAnchor(anchorScreen: CGPoint, anchorWorld: WorldPoint, canvasSize: CGSize, scale: Double) -> CGPoint {
        let originScreenX = anchorScreen.x - CGFloat(anchorWorld.x) * CGFloat(scale)
        let originScreenY = anchorScreen.y + CGFloat(anchorWorld.y) * CGFloat(scale)
        let center = CGSize(width: canvasSize.width, height: canvasSize.height).center
        return CGPoint(x: originScreenX - center.x, y: originScreenY - center.y)
    }

    private func tapGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { event in
                print("[Canvas] tapped")
                let location = event.location
                switch activeToolID {
                case "plane.point":
                    let world = screenToWorld(location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                    dispatch(.createPoint(at: world))

                case "plane.select":
                    if let hitID = hitTestObject(at: location, canvasSize: size) {
                        dispatch(.selectObject(id: hitID))
                    } else {
                        dispatch(.clearSelection)
                    }

                case "plane.delete":
                    if let hitID = hitTestObject(at: location, canvasSize: size) {
                        dispatch(.deleteObject(id: hitID))
                    } else {
                        dispatch(.clearSelection)
                    }

                case "plane.segment":
                    if let hit = resolvedPointHit(at: location, canvasSize: size) {
                        handleSegmentTap(world: hit.world, pointID: hit.id)
                    } else {
                        let world = screenToWorld(location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                        handleSegmentTap(world: world, pointID: nil)
                    }

                case "plane.midpoint":
                    handleMidpointTap(at: location, canvasSize: size)

                case "plane.line":
                    if let hit = resolvedPointHit(at: location, canvasSize: size) {
                        handleLineTap(world: hit.world, pointID: hit.id)
                    } else {
                        let world = screenToWorld(location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                        handleLineTap(world: world, pointID: nil)
                    }

                case "plane.ray":
                    if let hit = resolvedPointHit(at: location, canvasSize: size) {
                        handleRayTap(world: hit.world, pointID: hit.id)
                    } else {
                        let world = screenToWorld(location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                        handleRayTap(world: world, pointID: nil)
                    }

                case "plane.parallel":
                    handleParallelTap(at: location, canvasSize: size)

                case "plane.perpendicular":
                    handlePerpendicularTap(at: location, canvasSize: size)

                case "plane.circle":
                    if let hit = resolvedPointHit(at: location, canvasSize: size) {
                        handleCircleTap(world: hit.world, pointID: hit.id)
                    } else {
                        let world = screenToWorld(location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                        handleCircleTap(world: world, pointID: nil)
                    }

                case "plane.arc":
                    if let hit = resolvedPointHit(at: location, canvasSize: size) {
                        handleArcTap(world: hit.world, pointID: hit.id)
                    } else {
                        let world = screenToWorld(location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                        handleArcTap(world: world, pointID: nil)
                    }

                case "plane.intersection":
                    handleIntersectionTap(at: location, canvasSize: size)

                default:
                    break
                }
            }
    }

    private func hitTestObject(at screen: CGPoint, canvasSize: CGSize) -> UUID? {
        PlaneHitTestService.hitTestObject(
            at: screen,
            objects: objects,
            canvasState: canvasState,
            canvasSize: canvasSize
        )
    }

    @ViewBuilder
    private var constructionHintOverlay: some View {
        if let hint = interactionState.constructionHintText {
            HStack(spacing: 8) {
                Text(hint)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Button {
                    cancelCurrentConstruction()
                } label: {
                    Label("取消", systemImage: "xmark")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.14))
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.20), lineWidth: 0.75)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.10 : 0.04), radius: 6, x: 0, y: 3)
            .padding(.top, 12)
            .padding(.leading, 12)
            .allowsHitTesting(true)
        }
    }

    private func worldToScreen(_ world: WorldPoint, canvasSize: CGSize) -> CGPoint {
        worldToScreen(world, canvasSize: canvasSize, originOffset: canvasState.origin, scale: canvasState.scale)
    }

    private func cancelCurrentConstruction() {
        interactionState.clearConstructionProgress()
    }

    private func pointDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .local)
            .onChanged { value in
                guard activeToolID == "plane.select" else { return }

                if dragIntent == .none {
                    if let hitID = PlaneHitTestService.hitTestPoint(
                        at: value.startLocation,
                        objects: objects,
                        canvasState: canvasState,
                        canvasSize: size
                    ) {
                        dragIntent = .dragPoint(hitID)
                    } else {
                        dragIntent = .panCanvas
                    }
                }

                guard case .dragPoint(let lockedID) = dragIntent else { return }

                if interactionState.draggingObjectID == nil {
                    interactionState.draggingObjectID = lockedID
                    interactionState.isDraggingObject = true
                    dispatch(.setObjectDragging(id: lockedID, isDragging: true))
                    dispatch(.selectObject(id: lockedID))
                }

                guard let draggingPointID = interactionState.draggingObjectID else { return }
                let world = screenToWorld(value.location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                dispatch(.updateObjectPosition(id: draggingPointID, position: world))
            }
            .onEnded { _ in
                if let draggingID = interactionState.draggingObjectID {
                    dispatch(.setObjectDragging(id: draggingID, isDragging: false))
                }
                interactionState.draggingObjectID = nil
                interactionState.isDraggingObject = false
                dragIntent = .none
            }
    }

    private func handleSegmentTap(world: WorldPoint, pointID: UUID?) {
        switch interactionState.activeConstruction {
        case .segmentSecondPoint(let startWorldPoint, let startPointID):
            dispatchSegmentCreation(
                startWorldPoint: startWorldPoint,
                startPointID: startPointID,
                endWorldPoint: world,
                endPointID: pointID
            )
            interactionState = PlaneInteractionState()

        default:
            interactionState.activeConstruction = .segmentSecondPoint(startWorldPoint: world, startPointID: pointID)
            interactionState.pendingWorldPoint = world
            interactionState.pendingPointID = pointID
            interactionState.constructionPreview = .temporarySegment(start: world, current: world)
        }
    }

    private func handleCircleTap(world: WorldPoint, pointID: UUID?) {
        switch interactionState.activeConstruction {
        case .circleRadius(let centerPointID):
            guard let center = interactionState.pendingWorldPoint else { return }
            dispatchCircleCreation(
                centerPointID: centerPointID,
                throughPointID: pointID,
                centerWorldPoint: center,
                radiusWorldPoint: world
            )
            interactionState = PlaneInteractionState(
                activeConstruction: .circleCenter
            )

        default:
            interactionState.activeConstruction = .circleRadius(centerPointID: pointID)
            interactionState.pendingWorldPoint = world
            interactionState.pendingPointID = pointID
            interactionState.constructionPreview = .temporaryCircle(center: world, currentRadiusPoint: world)
        }
    }

    private func handleArcTap(world: WorldPoint, pointID: UUID?) {
        switch interactionState.activeConstruction {
        case .arcSecondPoint(let firstWorldPoint, let firstPointID):
            interactionState.activeConstruction = .arcThirdPoint(
                firstWorldPoint: firstWorldPoint, firstPointID: firstPointID,
                secondWorldPoint: world, secondPointID: pointID
            )
            interactionState.pendingWorldPoint = world
            interactionState.pendingPointID = pointID
            // Clear preview — no line shown during two-point phase.
            // Arc preview only appears during third-point drag (via constructionPreviewGesture).
            interactionState.constructionPreview = nil

        case .arcThirdPoint(let firstWorldPoint, let firstPointID,
                             let secondWorldPoint, let secondPointID):
            dispatchArcCreation(
                pointA: firstWorldPoint, pointAID: firstPointID,
                pointB: secondWorldPoint, pointBID: secondPointID,
                pointC: world, pointCID: pointID
            )
            interactionState = PlaneInteractionState(activeConstruction: .arcFirstPoint)

        default:
            interactionState.activeConstruction = .arcSecondPoint(
                firstWorldPoint: world, firstPointID: pointID
            )
            interactionState.pendingWorldPoint = world
            interactionState.pendingPointID = pointID
            interactionState.constructionPreview = nil
        }
    }

    private func handleLineTap(world: WorldPoint, pointID: UUID?) {
        switch interactionState.activeConstruction {
        case .lineSecondPoint(let startWorldPoint, let startPointID):
            dispatchLineCreation(
                pointA: startWorldPoint,
                pointAID: startPointID,
                pointB: world,
                pointBID: pointID
            )
            interactionState = PlaneInteractionState()

        default:
            interactionState.activeConstruction = .lineSecondPoint(startWorldPoint: world, startPointID: pointID)
            interactionState.pendingWorldPoint = world
            interactionState.pendingPointID = pointID
            interactionState.constructionPreview = .temporaryLine(pointA: world, pointB: world)
        }
    }

    private func handleRayTap(world: WorldPoint, pointID: UUID?) {
        switch interactionState.activeConstruction {
        case .raySecondPoint(let startWorldPoint, let startPointID):
            dispatchRayCreation(
                start: startWorldPoint,
                startID: startPointID,
                through: world,
                throughID: pointID
            )
            interactionState = PlaneInteractionState()

        default:
            interactionState.activeConstruction = .raySecondPoint(startWorldPoint: world, startPointID: pointID)
            interactionState.pendingWorldPoint = world
            interactionState.pendingPointID = pointID
            interactionState.constructionPreview = .temporaryRay(start: world, through: world)
        }
    }

    private func handleIntersectionTap(at location: CGPoint, canvasSize: CGSize) {
        guard let hitID = hitTestIntersectionTarget(at: location, canvasSize: canvasSize) else { return }

        if case .intersectionSecondObject(let firstObjectID) = interactionState.activeConstruction {
            guard firstObjectID != hitID else { return }
            dispatchIntersectionCreation(firstObjectID: firstObjectID, secondObjectID: hitID)
            interactionState = PlaneInteractionState()
            return
        }

        interactionState.activeConstruction = .intersectionSecondObject(firstObjectID: hitID)
        interactionState.constructionPreview = nil
        dispatch(.selectObject(id: hitID))
    }

    private func handleMidpointTap(at location: CGPoint, canvasSize: CGSize) {
        guard let hit = hitTestMidpointTarget(at: location, canvasSize: canvasSize) else { return }

        switch hit {
        case .segment(let segmentID):
            dispatchMidpointCreation(segmentID: segmentID, pointAID: nil, pointBID: nil)
            interactionState = PlaneInteractionState()

        case .point(let pointID, let world):
            if case .midpointSecondPoint(let firstPointID, _) = interactionState.activeConstruction {
                guard firstPointID != pointID else { return }
                dispatchMidpointCreation(segmentID: nil, pointAID: firstPointID, pointBID: pointID)
                interactionState = PlaneInteractionState()
                return
            }

            interactionState.activeConstruction = .midpointSecondPoint(
                firstPointID: pointID,
                firstWorldPoint: world
            )
            interactionState.pendingPointID = pointID
            interactionState.pendingWorldPoint = world
            interactionState.constructionPreview = nil
            dispatch(.selectObject(id: pointID))
        }
    }

    private func handleParallelTap(at location: CGPoint, canvasSize: CGSize) {
        guard let hit = hitTestDerivedLineTarget(at: location, canvasSize: canvasSize) else { return }
        switch hit {
        case .reference(let objectID):
            if case .parallelSecondReference(let pointID, _) = interactionState.activeConstruction {
                dispatchDerivedLineCreation(
                    commandID: "plane.createParallelLine",
                    referenceObjectID: objectID,
                    pointID: pointID
                )
                interactionState = PlaneInteractionState()
                return
            }
            interactionState.activeConstruction = .parallelSecondPoint(referenceObjectID: objectID)
            interactionState.pendingPointID = nil
            interactionState.pendingWorldPoint = nil
            interactionState.constructionPreview = nil
            dispatch(.selectObject(id: objectID))

        case .point(let pointID, let world):
            if case .parallelSecondPoint(let referenceObjectID) = interactionState.activeConstruction {
                dispatchDerivedLineCreation(
                    commandID: "plane.createParallelLine",
                    referenceObjectID: referenceObjectID,
                    pointID: pointID
                )
                interactionState = PlaneInteractionState()
                return
            }
            interactionState.activeConstruction = .parallelSecondReference(
                pointID: pointID,
                pointWorldPoint: world
            )
            interactionState.pendingPointID = pointID
            interactionState.pendingWorldPoint = world
            interactionState.constructionPreview = nil
            dispatch(.selectObject(id: pointID))
        }
    }

    private func handlePerpendicularTap(at location: CGPoint, canvasSize: CGSize) {
        guard let hit = hitTestDerivedLineTarget(at: location, canvasSize: canvasSize) else { return }
        switch hit {
        case .reference(let objectID):
            if case .perpendicularSecondReference(let pointID, _) = interactionState.activeConstruction {
                dispatchDerivedLineCreation(
                    commandID: "plane.createPerpendicularLine",
                    referenceObjectID: objectID,
                    pointID: pointID
                )
                interactionState = PlaneInteractionState()
                return
            }
            interactionState.activeConstruction = .perpendicularSecondPoint(referenceObjectID: objectID)
            interactionState.pendingPointID = nil
            interactionState.pendingWorldPoint = nil
            interactionState.constructionPreview = nil
            dispatch(.selectObject(id: objectID))

        case .point(let pointID, let world):
            if case .perpendicularSecondPoint(let referenceObjectID) = interactionState.activeConstruction {
                dispatchDerivedLineCreation(
                    commandID: "plane.createPerpendicularLine",
                    referenceObjectID: referenceObjectID,
                    pointID: pointID
                )
                interactionState = PlaneInteractionState()
                return
            }
            interactionState.activeConstruction = .perpendicularSecondReference(
                pointID: pointID,
                pointWorldPoint: world
            )
            interactionState.pendingPointID = pointID
            interactionState.pendingWorldPoint = world
            interactionState.constructionPreview = nil
            dispatch(.selectObject(id: pointID))
        }
    }

    private func dispatchSegmentCreation(
        startWorldPoint: WorldPoint,
        startPointID: UUID?,
        endWorldPoint: WorldPoint,
        endPointID: UUID?
    ) {
        let payload = PlaneSegmentCreatePayload(
            startPointID: startPointID,
            startWorldPoint: startWorldPoint,
            endPointID: endPointID,
            endWorldPoint: endWorldPoint
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) else {
            dispatch(.createSegment(start: startWorldPoint, end: endWorldPoint))
            return
        }
        dispatch(.moduleSpecific(id: "plane.createSegmentWithOptionalPoints", payload: json))
    }

    private func dispatchCircleCreation(
        centerPointID: UUID?,
        throughPointID: UUID?,
        centerWorldPoint: WorldPoint,
        radiusWorldPoint: WorldPoint
    ) {
        let payload = PlaneCircleCreatePayload(
            centerPointID: centerPointID,
            throughPointID: throughPointID,
            centerWorldPoint: centerWorldPoint,
            radiusWorldPoint: radiusWorldPoint
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) else {
            return
        }
        dispatch(.moduleSpecific(id: "plane.createCircleWithOptionalCenter", payload: json))
    }

    private func dispatchArcCreation(
        pointA: WorldPoint, pointAID: UUID?,
        pointB: WorldPoint, pointBID: UUID?,
        pointC: WorldPoint, pointCID: UUID?
    ) {
        let payload = PlaneArcCreatePayload(
            pointAID: pointAID, pointAWorldPoint: pointA,
            pointBID: pointBID, pointBWorldPoint: pointB,
            pointCID: pointCID, pointCWorldPoint: pointC
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) else {
            return
        }
        dispatch(.moduleSpecific(id: "plane.createArc", payload: json))
    }

    private func dispatchLineCreation(
        pointA: WorldPoint,
        pointAID: UUID?,
        pointB: WorldPoint,
        pointBID: UUID?
    ) {
        let payload = PlaneLineCreatePayload(
            pointAID: pointAID,
            pointAWorldPoint: pointA,
            pointBID: pointBID,
            pointBWorldPoint: pointB
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) else {
            dispatch(.createLine(pointA: pointA, pointB: pointB))
            return
        }
        dispatch(.moduleSpecific(id: "plane.createLineWithOptionalPoints", payload: json))
    }

    private func dispatchRayCreation(
        start: WorldPoint,
        startID: UUID?,
        through: WorldPoint,
        throughID: UUID?
    ) {
        let payload = PlaneRayCreatePayload(
            startPointID: startID,
            startWorldPoint: start,
            throughPointID: throughID,
            throughWorldPoint: through
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) else {
            dispatch(.createRay(start: start, through: through))
            return
        }
        dispatch(.moduleSpecific(id: "plane.createRayWithOptionalPoints", payload: json))
    }

    private func dispatchIntersectionCreation(firstObjectID: UUID, secondObjectID: UUID) {
        let payload = PlaneIntersectionCreatePayload(
            firstObjectID: firstObjectID,
            secondObjectID: secondObjectID
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) else {
            return
        }
        dispatch(.moduleSpecific(id: "plane.createIntersectionPoints", payload: json))
    }

    private func dispatchMidpointCreation(segmentID: UUID?, pointAID: UUID?, pointBID: UUID?) {
        let payload = PlaneMidpointCreatePayload(
            segmentID: segmentID,
            pointAID: pointAID,
            pointBID: pointBID
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) else {
            return
        }
        dispatch(.moduleSpecific(id: "plane.createMidpoint", payload: json))
    }

    private func dispatchDerivedLineCreation(commandID: String, referenceObjectID: UUID, pointID: UUID) {
        let payload = PlaneDerivedLinePayload(referenceObjectID: referenceObjectID, pointID: pointID)
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) else {
            return
        }
        dispatch(.moduleSpecific(id: commandID, payload: json))
    }

    private func resolvedPointHit(at location: CGPoint, canvasSize: CGSize) -> (id: UUID, world: WorldPoint)? {
        guard let hitID = PlaneHitTestService.hitTestPoint(
            at: location,
            objects: objects,
            canvasState: canvasState,
            canvasSize: canvasSize
        ),
              let point = objects.first(where: { $0.id == hitID }),
              let world = PlaneGeometryResolver.pointPosition(for: point) else {
            return nil
        }
        return (hitID, world)
    }

    private func hitTestIntersectionTarget(at location: CGPoint, canvasSize: CGSize) -> UUID? {
        let allowed: Set<MathObjectType> = [.segment, .line, .ray, .circle]
        return PlaneHitTestService.hitTestObject(
            at: location,
            objects: objects,
            canvasState: canvasState,
            canvasSize: canvasSize,
            allowedTypes: allowed
        )
    }

    private enum MidpointHitTarget {
        case point(UUID, WorldPoint)
        case segment(UUID)
    }

    private func hitTestMidpointTarget(at location: CGPoint, canvasSize: CGSize) -> MidpointHitTarget? {
        if let pointHit = resolvedPointHit(at: location, canvasSize: canvasSize) {
            return .point(pointHit.id, pointHit.world)
        }
        let allowed: Set<MathObjectType> = [.segment]
        guard let objectID = PlaneHitTestService.hitTestObject(
            at: location,
            objects: objects,
            canvasState: canvasState,
            canvasSize: canvasSize,
            allowedTypes: allowed
        ) else {
            return nil
        }
        return .segment(objectID)
    }

    private enum DerivedLineHitTarget {
        case point(UUID, WorldPoint)
        case reference(UUID)
    }

    private func hitTestDerivedLineTarget(at location: CGPoint, canvasSize: CGSize) -> DerivedLineHitTarget? {
        if let pointHit = resolvedPointHit(at: location, canvasSize: canvasSize) {
            return .point(pointHit.id, pointHit.world)
        }
        let allowed: Set<MathObjectType> = [.segment, .line, .ray]
        guard let objectID = PlaneHitTestService.hitTestObject(
            at: location,
            objects: objects,
            canvasState: canvasState,
            canvasSize: canvasSize,
            allowedTypes: allowed
        ) else {
            return nil
        }
        return .reference(objectID)
    }

    private func constructionPreviewGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if activeToolID == "plane.segment" {
                    guard case .segmentSecondPoint(let start, _) = interactionState.activeConstruction else { return }
                    if let hit = resolvedPointHit(at: value.location, canvasSize: size) {
                        interactionState.constructionPreview = .temporarySegment(start: start, current: hit.world)
                        return
                    }
                    let current = screenToWorld(value.location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                    interactionState.constructionPreview = .temporarySegment(start: start, current: current)
                    return
                }

                if activeToolID == "plane.line" {
                    guard case .lineSecondPoint(let start, _) = interactionState.activeConstruction else { return }
                    if let hit = resolvedPointHit(at: value.location, canvasSize: size) {
                        interactionState.constructionPreview = .temporaryLine(pointA: start, pointB: hit.world)
                        return
                    }
                    let current = screenToWorld(value.location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                    interactionState.constructionPreview = .temporaryLine(pointA: start, pointB: current)
                    return
                }

                if activeToolID == "plane.ray" {
                    guard case .raySecondPoint(let start, _) = interactionState.activeConstruction else { return }
                    if let hit = resolvedPointHit(at: value.location, canvasSize: size) {
                        interactionState.constructionPreview = .temporaryRay(start: start, through: hit.world)
                        return
                    }
                    let current = screenToWorld(value.location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                    interactionState.constructionPreview = .temporaryRay(start: start, through: current)
                    return
                }

                if activeToolID == "plane.circle" {
                    guard case .circleRadius = interactionState.activeConstruction,
                          let center = interactionState.pendingWorldPoint else { return }
                    if let hit = resolvedPointHit(at: value.location, canvasSize: size) {
                        interactionState.constructionPreview = .temporaryCircle(center: center, currentRadiusPoint: hit.world)
                        return
                    }
                    let current = screenToWorld(value.location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                    interactionState.constructionPreview = .temporaryCircle(center: center, currentRadiusPoint: current)
                    return
                }

                if activeToolID == "plane.arc" {
                    guard case .arcThirdPoint(let pointA, _, let pointB, _) = interactionState.activeConstruction else { return }
                    let pointC: WorldPoint
                    if let hit = resolvedPointHit(at: value.location, canvasSize: size) {
                        pointC = hit.world
                    } else {
                        pointC = screenToWorld(value.location, canvasSize: size, originOffset: canvasState.origin, scale: canvasState.scale)
                    }
                    if PlaneGeometryResolver.arcFromThreePoints(pointA, pointB, pointC) != nil {
                        interactionState.constructionPreview = .temporaryArc(pointA: pointA, pointB: pointB, pointC: pointC)
                    } else {
                        interactionState.constructionPreview = nil
                    }
                    return
                }

                if activeToolID == "plane.intersection" {
                    guard case .intersectionSecondObject(let firstObjectID) = interactionState.activeConstruction else {
                        interactionState.constructionPreview = nil
                        return
                    }
                    guard let secondObjectID = hitTestIntersectionTarget(at: value.location, canvasSize: size),
                          secondObjectID != firstObjectID else {
                        interactionState.constructionPreview = nil
                        return
                    }
                    let previewPoints = PlaneIntersectionPreviewResolver.previewPoints(
                        firstObjectID: firstObjectID,
                        secondObjectID: secondObjectID,
                        objects: objects
                    )
                    interactionState.constructionPreview = previewPoints.isEmpty
                        ? nil
                        : .temporaryIntersections(points: previewPoints)
                }
            }
            .onEnded { _ in
                // Keep preview until second tap completes construction.
            }
    }

    private enum PlaneDragIntent: Equatable {
        case none
        case panCanvas
        case dragPoint(UUID)
    }

    private struct PlaneSegmentCreatePayload: Codable {
        let startPointID: UUID?
        let startWorldPoint: WorldPoint
        let endPointID: UUID?
        let endWorldPoint: WorldPoint
    }

    private struct PlaneCircleCreatePayload: Codable {
        let centerPointID: UUID?
        let throughPointID: UUID?
        let centerWorldPoint: WorldPoint
        let radiusWorldPoint: WorldPoint
    }

    private struct PlaneLineCreatePayload: Codable {
        let pointAID: UUID?
        let pointAWorldPoint: WorldPoint
        let pointBID: UUID?
        let pointBWorldPoint: WorldPoint
    }

    private struct PlaneRayCreatePayload: Codable {
        let startPointID: UUID?
        let startWorldPoint: WorldPoint
        let throughPointID: UUID?
        let throughWorldPoint: WorldPoint
    }

    private struct PlaneIntersectionCreatePayload: Codable {
        let firstObjectID: UUID
        let secondObjectID: UUID
    }

    private struct PlaneMidpointCreatePayload: Codable {
        let segmentID: UUID?
        let pointAID: UUID?
        let pointBID: UUID?
    }

    private struct PlaneDerivedLinePayload: Codable {
        let referenceObjectID: UUID
        let pointID: UUID
    }
}
