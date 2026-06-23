import EMathicaWorkspaceKit
import EMathicaMathCore
import SwiftUI

struct SpaceCanvasView: View {
    @Environment(\.colorScheme) private var colorScheme

    let objects: [MathObject]
    let selectedObjectIDs: Set<UUID>
    let activeToolID: String
    let cameraState: SpaceCameraState
    let workPlane: SpaceWorkPlane
    let dispatch: (WorkspaceCommand) -> Void

    @State private var dragStartCamera: SpaceCameraState?
    @State private var zoomStartCamera: SpaceCameraState?
    @State private var isInteracting = false
    @State private var pendingSegmentStart: WorldPoint3D?
    @State private var pendingLineStart: WorldPoint3D?
    @State private var pendingPlanePoints: [WorldPoint3D] = []

    var body: some View {
        GeometryReader { proxy in
            let viewport = SpaceViewportSize(
                width: max(1, proxy.size.width),
                height: max(1, proxy.size.height)
            )
            let scene = SpaceWireframeRenderer.buildScene(
                objects: objects,
                camera: cameraState,
                viewport: viewport
            )

            Canvas { context, _ in
                context.fill(
                    Path(CGRect(origin: .zero, size: proxy.size)),
                    with: .color(SpaceCanvasStyle.backgroundColor(for: colorScheme))
                )

                for polygon in scene.polygons {
                    guard polygon.corners.count >= 3 else { continue }
                    var path = Path()
                    path.move(to: CGPoint(x: polygon.corners[0].x, y: polygon.corners[0].y))
                    for corner in polygon.corners.dropFirst() {
                        path.addLine(to: CGPoint(x: corner.x, y: corner.y))
                    }
                    path.closeSubpath()
                    context.fill(path, with: .color(fillColor(for: polygon.style)))
                }

                for segment in scene.segments {
                    var path = Path()
                    path.move(to: CGPoint(x: segment.start.x, y: segment.start.y))
                    path.addLine(to: CGPoint(x: segment.end.x, y: segment.end.y))
                    let selected = isSelected(segment.sourceObjectID)
                    context.stroke(
                        path,
                        with: .color(segmentColor(for: segment.style, selected: selected)),
                        style: StrokeStyle(lineWidth: lineWidth(for: segment.style, selected: selected), lineCap: .round)
                    )
                }

                for point in scene.points {
                    let selected = isSelected(point.sourceObjectID)
                    let radius = pointRadius(for: point.style, selected: selected)
                    let rect = CGRect(
                        x: point.projected.x - radius,
                        y: point.projected.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(color(for: point.style)))
                    if selected {
                        context.stroke(
                            Path(ellipseIn: rect.insetBy(dx: -2.0, dy: -2.0)),
                            with: .color(Color.yellow.opacity(0.9)),
                            style: StrokeStyle(lineWidth: 1.5)
                        )
                    }
                }

                for label in scene.labels {
                    let text = Text(label.text)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color(for: label.style))
                    context.draw(
                        text,
                        at: CGPoint(x: label.projected.x, y: label.projected.y),
                        anchor: .center
                    )
                }
            }
            .overlay(alignment: .topTrailing) {
                Picker("工作平面", selection: Binding(
                    get: { workPlane },
                    set: { newValue in
                        dispatch(.setSpaceWorkPlane(newValue))
                    }
                )) {
                    ForEach(SpaceWorkPlane.allCases, id: \.self) { plane in
                        Text(plane.label).tag(plane)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
                .padding(.top, 12)
                .padding(.trailing, 12)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .simultaneousGesture(zoomGesture)
            .simultaneousGesture(tapGesture(in: viewport))
            .onChange(of: activeToolID) { _, _ in
                if activeToolID != SpaceToolIDs.segment3D {
                    pendingSegmentStart = nil
                }
                if activeToolID != SpaceToolIDs.line3D {
                    pendingLineStart = nil
                }
                if activeToolID != SpaceToolIDs.plane3D {
                    pendingPlanePoints = []
                }
            }
            .onChange(of: workPlane) { _, _ in
                pendingSegmentStart = nil
                pendingLineStart = nil
                pendingPlanePoints = []
            }
            .onDisappear {
                endInteractionIfNeeded()
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStartCamera == nil {
                    dragStartCamera = cameraState
                    beginInteractionIfNeeded()
                }
                guard let start = dragStartCamera else { return }

                let dx = value.translation.width
                let dy = value.translation.height
                let next: SpaceCameraState
                if activeToolID == SpaceToolIDs.pan {
                    let scale = max(0.002, start.clampedDistance * 0.0015)
                    next = start.pan(deltaX: -Double(dx) * scale, deltaY: Double(dy) * scale)
                } else {
                    // Direct-manipulation feel:
                    // drag right -> scene follows right, drag up -> tilt upward.
                    let orbitScale = 0.008
                    next = start.orbit(
                        deltaYaw: Double(dx) * orbitScale,
                        deltaPitch: Double(dy) * orbitScale
                    )
                }
                dispatch(.setSpaceCameraState(next))
            }
            .onEnded { _ in
                dragStartCamera = nil
                endInteractionIfNeeded()
            }
    }

    private func tapGesture(in viewport: SpaceViewportSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { event in
                let scene = SpaceWireframeRenderer.buildScene(
                    objects: objects,
                    camera: cameraState,
                    viewport: viewport
                )

                if activeToolID == SpaceToolIDs.select {
                    if let hit = SpaceHitTestService.hitTest(tapPoint: event.location, scene: scene) {
                        dispatch(.selectObject(id: hit.objectID))
                    } else {
                        dispatch(.clearSelection)
                    }
                    return
                }

                switch activeToolID {
                case SpaceToolIDs.point3D:
                    let world = SpaceGeometryResolver.screenPointToWorkPlane(
                        event.location,
                        workPlane: workPlane,
                        viewportSize: viewport,
                        camera: cameraState
                    )
                    guard let world else { return }
                    dispatchCreatePoint3D(world)
                case SpaceToolIDs.segment3D:
                    let world = SpaceGeometryResolver.snappedOrWorkPlanePoint(
                        screenPoint: event.location,
                        objects: objects,
                        scene: scene,
                        viewportSize: viewport,
                        camera: cameraState,
                        workPlane: workPlane
                    )
                    guard let world else { return }
                    handleSegmentTap(world)
                case SpaceToolIDs.line3D:
                    let world = SpaceGeometryResolver.snappedOrWorkPlanePoint(
                        screenPoint: event.location,
                        objects: objects,
                        scene: scene,
                        viewportSize: viewport,
                        camera: cameraState,
                        workPlane: workPlane
                    )
                    guard let world else { return }
                    handleLineTap(world)
                case SpaceToolIDs.plane3D:
                    let world = SpaceGeometryResolver.snappedOrWorkPlanePoint(
                        screenPoint: event.location,
                        objects: objects,
                        scene: scene,
                        viewportSize: viewport,
                        camera: cameraState,
                        workPlane: workPlane
                    )
                    guard let world else { return }
                    handlePlaneTap(world)
                default:
                    break
                }
            }
    }

    private func handleSegmentTap(_ world: WorldPoint3D) {
        guard let start = pendingSegmentStart else {
            pendingSegmentStart = world
            return
        }
        dispatchCreateSegment3D(pointA: start, pointB: world)
        pendingSegmentStart = nil
    }

    private func dispatchCreatePoint3D(_ point: WorldPoint3D) {
        let payload = SpacePointCreatePayload(point: point)
        guard let json = encodePayload(payload) else { return }
        dispatch(.moduleSpecific(id: "space.createPoint3D", payload: json))
    }

    private func dispatchCreateSegment3D(pointA: WorldPoint3D, pointB: WorldPoint3D) {
        let payload = SpaceSegmentCreatePayload(pointA: pointA, pointB: pointB)
        guard let json = encodePayload(payload) else { return }
        dispatch(.moduleSpecific(id: "space.createSegment3D", payload: json))
    }

    private func handleLineTap(_ world: WorldPoint3D) {
        guard let start = pendingLineStart else {
            pendingLineStart = world
            return
        }
        let direction = world - start
        if direction.length <= 1e-8 {
            pendingLineStart = nil
            return
        }
        dispatchCreateLine3D(point: start, direction: direction)
        pendingLineStart = nil
    }

    private func dispatchCreateLine3D(point: WorldPoint3D, direction: Vector3D) {
        let payload = SpaceLineCreatePayload(point: point, direction: direction)
        guard let json = encodePayload(payload) else { return }
        dispatch(.moduleSpecific(id: "space.createLine3D", payload: json))
    }

    private func handlePlaneTap(_ world: WorldPoint3D) {
        if pendingPlanePoints.count < 2 {
            pendingPlanePoints.append(world)
            return
        }

        let a = pendingPlanePoints[0]
        let b = pendingPlanePoints[1]
        let c = world

        guard let normal = SpaceGeometryResolver.planeNormalFromThreePoints(a, b, c) else {
            pendingPlanePoints = []
            return
        }

        dispatchCreatePlane3D(point: a, normal: normal)
        pendingPlanePoints = []
    }

    private func dispatchCreatePlane3D(point: WorldPoint3D, normal: Vector3D) {
        let payload = SpacePlaneCreatePayload(point: point, normal: normal)
        guard let json = encodePayload(payload) else { return }
        dispatch(.moduleSpecific(id: "space.createPlane3D", payload: json))
    }

    private func encodePayload<T: Encodable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if zoomStartCamera == nil {
                    zoomStartCamera = cameraState
                    beginInteractionIfNeeded()
                }
                guard let start = zoomStartCamera else { return }
                let magnification = max(0.05, value.magnification)
                let desired = start.clampedDistance / Double(magnification)
                let delta = desired - start.clampedDistance
                dispatch(.setSpaceCameraState(start.zoom(delta: delta)))
            }
            .onEnded { _ in
                zoomStartCamera = nil
                endInteractionIfNeeded()
            }
    }

    private func beginInteractionIfNeeded() {
        guard !isInteracting else { return }
        isInteracting = true
        dispatch(.setCanvasInteracting(true))
    }

    private func endInteractionIfNeeded() {
        guard isInteracting else { return }
        isInteracting = false
        dispatch(.setCanvasInteracting(false))
    }

    private func color(for style: SpaceWireframeStyle) -> Color {
        switch style {
        case .axisX:
            return colorScheme == .dark ? Color(red: 0.95, green: 0.36, blue: 0.36) : Color(red: 0.72, green: 0.12, blue: 0.12)
        case .axisY:
            return colorScheme == .dark ? Color(red: 0.35, green: 0.85, blue: 0.45) : Color(red: 0.08, green: 0.52, blue: 0.16)
        case .axisZ:
            return colorScheme == .dark ? Color(red: 0.38, green: 0.58, blue: 0.96) : Color(red: 0.08, green: 0.30, blue: 0.72)
        case .plane:
            return colorScheme == .dark ? Color.cyan.opacity(0.82) : Color.blue.opacity(0.78)
        case .point:
            return colorScheme == .dark ? Color.white : Color.black
        case .object:
            return colorScheme == .dark ? Color.white.opacity(0.95) : Color.black.opacity(0.88)
        }
    }

    private func lineWidth(for style: SpaceWireframeStyle) -> CGFloat {
        lineWidth(for: style, selected: false)
    }

    private func lineWidth(for style: SpaceWireframeStyle, selected: Bool) -> CGFloat {
        let base: CGFloat
        switch style {
        case .axisX, .axisY, .axisZ:
            base = 2.4
        case .plane:
            base = 1.2
        case .object:
            base = 1.4
        case .point:
            base = 1.0
        }
        return selected ? base + 1.2 : base
    }

    private func pointRadius(for style: SpaceWireframeStyle) -> CGFloat {
        pointRadius(for: style, selected: false)
    }

    private func pointRadius(for style: SpaceWireframeStyle, selected: Bool) -> CGFloat {
        let base: CGFloat
        switch style {
        case .point:
            base = 2.8
        default:
            base = 2.2
        }
        return selected ? base + 1.8 : base
    }

    private func fillColor(for style: SpaceWireframeStyle) -> Color {
        switch style {
        case .plane:
            return colorScheme == .dark ? Color.cyan.opacity(0.14) : Color.blue.opacity(0.12)
        default:
            return .clear
        }
    }

    private func segmentColor(for style: SpaceWireframeStyle, selected: Bool) -> Color {
        guard selected else { return color(for: style) }
        return Color.yellow.opacity(colorScheme == .dark ? 0.95 : 0.88)
    }

    private func isSelected(_ sourceObjectID: UUID?) -> Bool {
        guard let sourceObjectID else { return false }
        return selectedObjectIDs.contains(sourceObjectID)
    }
}

enum SpaceCanvasStyle {
    static func usesDarkBackground(for colorScheme: ColorScheme) -> Bool {
        colorScheme == .dark
    }

    static func backgroundColor(for colorScheme: ColorScheme) -> Color {
        usesDarkBackground(for: colorScheme) ? Color.black.opacity(0.98) : Color(.systemBackground)
    }
}

private struct SpacePointCreatePayload: Codable {
    var point: WorldPoint3D
}

private struct SpaceSegmentCreatePayload: Codable {
    var pointA: WorldPoint3D
    var pointB: WorldPoint3D
}

private struct SpaceLineCreatePayload: Codable {
    var point: WorldPoint3D
    var direction: Vector3D
}

private struct SpacePlaneCreatePayload: Codable {
    var point: WorldPoint3D
    var normal: Vector3D
}
