import Foundation
import CoreGraphics
import EMathicaMathCore

enum PlaneHitTestService {
    static func hitTestPoint(
        at screen: CGPoint,
        objects: [MathObject],
        canvasState: CanvasState,
        canvasSize: CGSize,
        allowedTypes: Set<MathObjectType>? = nil
    ) -> UUID? {
        if let allowedTypes, !allowedTypes.contains(.point) {
            return nil
        }
        let radius: CGFloat = 12
        for object in objects.reversed() where object.type == .point && object.isVisible {
            if object.geometryDependency != nil,
               (object.geometryDefinitionStatus ?? .defined) != .defined {
                continue
            }
            guard let p = PlaneGeometryResolver.pointPosition(for: object) else { continue }
            let sp = worldToScreen(
                p,
                canvasSize: canvasSize,
                originOffset: canvasState.origin,
                scale: canvasState.scale
            )
            let dx = sp.x - screen.x
            let dy = sp.y - screen.y
            if (dx * dx + dy * dy) <= radius * radius {
                return object.id
            }
        }
        return nil
    }

    static func hitTestObject(
        at screen: CGPoint,
        objects: [MathObject],
        canvasState: CanvasState,
        canvasSize: CGSize,
        allowedTypes: Set<MathObjectType>? = nil
    ) -> UUID? {
        if let pointID = hitTestPoint(
            at: screen,
            objects: objects,
            canvasState: canvasState,
            canvasSize: canvasSize,
            allowedTypes: allowedTypes
        ) {
            return pointID
        }

        let threshold: CGFloat = 12
        let parameterValues = currentParameterValues(objects: objects)
        let parameterSymbolNames = Set(parameterValues.keys)

        for object in objects.reversed() where object.isVisible {
            if object.geometryDependency != nil,
               (object.geometryDefinitionStatus ?? .defined) != .defined {
                continue
            }
            if let allowedTypes, !allowedTypes.contains(object.type) {
                continue
            }
            if object.type == .parameter || object.type == .parameterGroup {
                continue
            }

            if let semanticSegments = semanticPlotSegments(
                for: object,
                parameterSymbolNames: parameterSymbolNames,
                parameterValues: parameterValues,
                canvasState: canvasState,
                canvasSize: canvasSize
            ),
               segmentsContainHit(
                semanticSegments,
                screen: screen,
                canvasState: canvasState,
                canvasSize: canvasSize,
                threshold: threshold
               ) {
                return object.id
            }

            switch object.type {
            case .segment:
                guard let endpoints = PlaneGeometryResolver.segmentEndpoints(for: object, in: objects) else { continue }
                let a = worldToScreen(
                    endpoints.0,
                    canvasSize: canvasSize,
                    originOffset: canvasState.origin,
                    scale: canvasState.scale
                )
                let b = worldToScreen(
                    endpoints.1,
                    canvasSize: canvasSize,
                    originOffset: canvasState.origin,
                    scale: canvasState.scale
                )
                if distance(from: screen, toSegmentFrom: a, to: b) <= threshold {
                    return object.id
                }

            case .line:
                guard let endpoints = PlaneGeometryResolver.linePoints(for: object, in: objects),
                      let clipped = PlaneLineClipping.clipInfiniteLine(
                        pointA: endpoints.0,
                        pointB: endpoints.1,
                        visibleWorldRect: canvasState.visibleWorldRect(in: canvasSize)
                      ) else { continue }
                let a = worldToScreen(clipped.0, canvasSize: canvasSize, originOffset: canvasState.origin, scale: canvasState.scale)
                let b = worldToScreen(clipped.1, canvasSize: canvasSize, originOffset: canvasState.origin, scale: canvasState.scale)
                if distance(from: screen, toSegmentFrom: a, to: b) <= threshold {
                    return object.id
                }

            case .ray:
                guard let endpoints = PlaneGeometryResolver.rayPoints(for: object, in: objects),
                      let clipped = PlaneLineClipping.clipRay(
                        start: endpoints.0,
                        through: endpoints.1,
                        visibleWorldRect: canvasState.visibleWorldRect(in: canvasSize)
                      ) else { continue }
                let a = worldToScreen(clipped.0, canvasSize: canvasSize, originOffset: canvasState.origin, scale: canvasState.scale)
                let b = worldToScreen(clipped.1, canvasSize: canvasSize, originOffset: canvasState.origin, scale: canvasState.scale)
                if distance(from: screen, toSegmentFrom: a, to: b) <= threshold {
                    return object.id
                }

            case .circle:
                if let circle = PlaneGeometryResolver.circleGeometry(for: object, in: objects),
                   circleHits(
                    screen: screen,
                    center: circle.center,
                    radius: circle.radius,
                    canvasState: canvasState,
                    canvasSize: canvasSize,
                    threshold: threshold
                   ) {
                    return object.id
                }
                guard let analysis = object.expression.algebraAnalysis else { continue }

            case .arc:
                if let arc = PlaneGeometryResolver.arcGeometry(for: object, in: objects),
                   arcHits(
                    screen: screen,
                    center: arc.center,
                    radius: arc.radius,
                    startAngle: arc.startAngle,
                    endAngle: arc.endAngle,
                    canvasState: canvasState,
                    canvasSize: canvasSize,
                    threshold: threshold
                   ) {
                    return object.id
                }

            case .function, .point:
                guard let analysis = object.expression.algebraAnalysis else { continue }
                if algebraObject(
                    analysis,
                    hits: screen,
                    objects: objects,
                    canvasState: canvasState,
                    canvasSize: canvasSize,
                    threshold: threshold,
                    parameterValues: parameterValues
                ) {
                    return object.id
                }

            case .parameter, .parameterGroup:
                continue
            }
        }

        return nil
    }

    private static func algebraObject(
        _ analysis: AlgebraAnalysisResult,
        hits screen: CGPoint,
        objects: [MathObject],
        canvasState: CanvasState,
        canvasSize: CGSize,
        threshold: CGFloat,
        parameterValues: [String: Double]
    ) -> Bool {
        if analysis.plotStrategy == .parametric, let curve = analysis.rewriteInfo?.curve {
            let segments = ParametricCurveSampler.sample(curve, viewport: canvasState, canvasSize: canvasSize, parameterValues: parameterValues)
            return segmentsContainHit(
                segments,
                screen: screen,
                canvasState: canvasState,
                canvasSize: canvasSize,
                threshold: threshold
            )
        }

        switch analysis.classification.kind {
        case .explicitY:
            guard let expression = analysis.classification.renderExpression else { return false }
            let segments = sampleExplicitY(expression, canvasState: canvasState, canvasSize: canvasSize, parameterValues: parameterValues)
            return segmentsContainHit(
                segments,
                screen: screen,
                canvasState: canvasState,
                canvasSize: canvasSize,
                threshold: threshold
            )

        case .explicitX:
            guard let expression = analysis.classification.renderExpression else { return false }
            let segments = sampleExplicitX(expression, canvasState: canvasState, canvasSize: canvasSize, parameterValues: parameterValues)
            return segmentsContainHit(
                segments,
                screen: screen,
                canvasState: canvasState,
                canvasSize: canvasSize,
                threshold: threshold
            )

        case .horizontalLine:
            guard let y = analysis.classification.centerY else { return false }
            let a = worldToScreen(
                WorldPoint(x: -1000, y: y),
                canvasSize: canvasSize,
                originOffset: canvasState.origin,
                scale: canvasState.scale
            )
            let b = worldToScreen(
                WorldPoint(x: 1000, y: y),
                canvasSize: canvasSize,
                originOffset: canvasState.origin,
                scale: canvasState.scale
            )
            return distance(from: screen, toSegmentFrom: a, to: b) <= threshold

        case .verticalLine:
            guard let x = analysis.classification.centerX else { return false }
            let a = worldToScreen(
                WorldPoint(x: x, y: -1000),
                canvasSize: canvasSize,
                originOffset: canvasState.origin,
                scale: canvasState.scale
            )
            let b = worldToScreen(
                WorldPoint(x: x, y: 1000),
                canvasSize: canvasSize,
                originOffset: canvasState.origin,
                scale: canvasState.scale
            )
            return distance(from: screen, toSegmentFrom: a, to: b) <= threshold

        case .circle, .ellipse:
            let segments = sampleEllipse(analysis.classification)
            return segmentsContainHit(
                segments,
                screen: screen,
                canvasState: canvasState,
                canvasSize: canvasSize,
                threshold: threshold
            )

        case .superellipse, .hyperbola, .parabola, .implicitPlaneCurve, .unsupported:
            return false
        }
    }

    private static func sampleExplicitY(
        _ expression: AlgebraExpression,
        canvasState: CanvasState,
        canvasSize: CGSize,
        parameterValues: [String: Double]
    ) -> [PlotSegment] {
        let rect = canvasState.visibleWorldRect(in: canvasSize)
        let samples = min(2400, max(240, Int(canvasSize.width / 1.5)))
        return PlaneLegacyExplicitSampling.sampleExplicitY(
            expression,
            visibleWorldRect: rect,
            samples: samples,
            parameterValues: parameterValues
        )
    }

    private static func sampleExplicitX(
        _ expression: AlgebraExpression,
        canvasState: CanvasState,
        canvasSize: CGSize,
        parameterValues: [String: Double]
    ) -> [PlotSegment] {
        let rect = canvasState.visibleWorldRect(in: canvasSize)
        let samples = min(2400, max(240, Int(canvasSize.height / 1.5)))
        return PlaneLegacyExplicitSampling.sampleExplicitX(
            expression,
            visibleWorldRect: rect,
            samples: samples,
            parameterValues: parameterValues
        )
    }

    private static func sampleEllipse(_ classification: AlgebraClassification) -> [PlotSegment] {
        let cx = classification.centerX ?? 0
        let cy = classification.centerY ?? 0
        let rx = classification.radiusX ?? classification.radius ?? 1
        let ry = classification.radiusY ?? classification.radius ?? 1
        let points = (0...160).map { index in
            let angle = Double(index) / 160 * 2 * Double.pi
            return WorldPoint(x: cx + rx * cos(angle), y: cy + ry * sin(angle))
        }
        return [PlotSegment(points: points)]
    }

    private static func segmentsContainHit(
        _ segments: [PlotSegment],
        screen: CGPoint,
        canvasState: CanvasState,
        canvasSize: CGSize,
        threshold: CGFloat
    ) -> Bool {
        for segment in segments where segment.points.count > 1 {
            let screenPoints = segment.points.map {
                worldToScreen(
                    $0,
                    canvasSize: canvasSize,
                    originOffset: canvasState.origin,
                    scale: canvasState.scale
                )
            }
            for index in 1..<screenPoints.count {
                if distance(from: screen, toSegmentFrom: screenPoints[index - 1], to: screenPoints[index]) <= threshold {
                    return true
                }
            }
        }
        return false
    }

    private static func circleHits(
        screen: CGPoint,
        center: WorldPoint,
        radius: Double,
        canvasState: CanvasState,
        canvasSize: CGSize,
        threshold: CGFloat
    ) -> Bool {
        guard radius.isFinite, radius > 0 else { return false }
        let centerScreen = worldToScreen(
            center,
            canvasSize: canvasSize,
            originOffset: canvasState.origin,
            scale: canvasState.scale
        )
        let edgeScreen = worldToScreen(
            WorldPoint(x: center.x + radius, y: center.y),
            canvasSize: canvasSize,
            originOffset: canvasState.origin,
            scale: canvasState.scale
        )
        let pixelRadius = hypot(edgeScreen.x - centerScreen.x, edgeScreen.y - centerScreen.y)
        let distanceToCenter = hypot(screen.x - centerScreen.x, screen.y - centerScreen.y)
        return abs(distanceToCenter - pixelRadius) <= threshold
    }

    private static func arcHits(
        screen: CGPoint,
        center: WorldPoint,
        radius: Double,
        startAngle: Double,
        endAngle: Double,
        canvasState: CanvasState,
        canvasSize: CGSize,
        threshold: CGFloat
    ) -> Bool {
        guard radius.isFinite, radius > 0 else { return false }
        // Check distance to circle
        let centerScreen = worldToScreen(center, canvasSize: canvasSize, originOffset: canvasState.origin, scale: canvasState.scale)
        let edgeScreen = worldToScreen(
            WorldPoint(x: center.x + radius, y: center.y),
            canvasSize: canvasSize, originOffset: canvasState.origin, scale: canvasState.scale
        )
        let pixelRadius = hypot(edgeScreen.x - centerScreen.x, edgeScreen.y - centerScreen.y)
        let distanceToCenter = hypot(screen.x - centerScreen.x, screen.y - centerScreen.y)
        guard abs(distanceToCenter - pixelRadius) <= threshold else { return false }

        // Check angle within arc sweep.
        // arc angles (startAngle/endAngle) are in world space (Y-up).
        // screenToWorld inverts Y, so atan2(screen_dy, screen_dx) = -atan2(world_dy, world_dx).
        // Negate to get the world-space angle of the hit point.
        let hitWorldAngle = -atan2(screen.y - centerScreen.y, screen.x - centerScreen.x)
        var sweepStart = startAngle
        var sweepEnd = endAngle
        if sweepEnd < sweepStart { sweepEnd += 2 * .pi }
        var a = hitWorldAngle
        if a < sweepStart { a += 2 * .pi }
        return a >= sweepStart - 0.01 && a <= sweepEnd + 0.01
    }

    private static func semanticPlotSegments(
        for object: MathObject,
        parameterSymbolNames: Set<String>,
        parameterValues: [String: Double],
        canvasState: CanvasState,
        canvasSize: CGSize
    ) -> [PlotSegment]? {
        guard let intent = PlaneSemanticIntentResolver.resolveIntent(
            for: object.expression,
            parameterSymbolNames: parameterSymbolNames
        ) else {
            return nil
        }
        guard PlaneSemanticPreviewPolicy().shouldUseSemanticPreview(for: intent) else {
            return nil
        }

        let visible = canvasState.visibleWorldRect(in: canvasSize)
        let xRange = SamplingRange(lower: visible.minX, upper: visible.maxX)
        let yRange = SamplingRange(lower: visible.minY, upper: visible.maxY)
        let viewport = SamplingViewport2D(
            xRange: xRange,
            yRange: yRange,
            pixelWidth: max(1, canvasSize.width),
            pixelHeight: max(1, canvasSize.height)
        )
        let sampleSet = GraphIntentSampler2D(qualityProfile: .balanced).sample(
            intent: intent,
            xRange: xRange,
            yRange: yRange,
            viewport: viewport,
            environment: EvaluationEnvironment.variables(parameterValues)
        )
        return PlaneSampleSetAdapter.adaptToPlotSegments(sampleSet)
    }

    private static func currentParameterValues(objects: [MathObject]) -> [String: Double] {
        Dictionary(
            uniqueKeysWithValues: objects.compactMap { object -> (String, Double)? in
                guard object.type == .parameter, let value = object.parameterValue else { return nil }
                return (object.name, value)
            }
        )
    }

    private static func worldToScreen(
        _ world: WorldPoint,
        canvasSize: CGSize,
        originOffset: CGPoint,
        scale: Double
    ) -> CGPoint {
        let originScreen = CGPoint(
            x: canvasSize.width * 0.5 + originOffset.x,
            y: canvasSize.height * 0.5 + originOffset.y
        )
        return CGPoint(
            x: originScreen.x + CGFloat(world.x) * CGFloat(scale),
            y: originScreen.y - CGFloat(world.y) * CGFloat(scale)
        )
    }

    private static func distance(from point: CGPoint, toSegmentFrom a: CGPoint, to b: CGPoint) -> CGFloat {
        let ab = CGVector(dx: b.x - a.x, dy: b.y - a.y)
        let ap = CGVector(dx: point.x - a.x, dy: point.y - a.y)
        let lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy
        guard lengthSquared > 0 else {
            return hypot(point.x - a.x, point.y - a.y)
        }

        let projection = max(0, min(1, (ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared))
        let closest = CGPoint(x: a.x + ab.dx * projection, y: a.y + ab.dy * projection)
        return hypot(point.x - closest.x, point.y - closest.y)
    }
}
