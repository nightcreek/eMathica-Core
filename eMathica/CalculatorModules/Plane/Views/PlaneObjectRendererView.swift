import EMathicaWorkspaceKit
import EMathicaThemeKit
import SwiftUI
import EMathicaMathCore

struct PlaneObjectRendererView: View {
    @Environment(\.colorScheme) private var colorScheme

    let canvasState: CanvasState
    let objects: [MathObject]
    let selectedObjectID: UUID?
    let draftMathObject: DraftMathObject?
    let constructionPreview: PlaneConstructionPreview?

    var body: some View {
        Canvas { context, size in
            let scale = CGFloat(canvasState.scale)
            let origin = CGPoint(x: size.width * 0.5 + canvasState.origin.x, y: size.height * 0.5 + canvasState.origin.y)

            func toScreen(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(
                    x: origin.x + CGFloat(x) * scale,
                    y: origin.y - CGFloat(y) * scale
                )
            }

            if let constructionPreview {
                drawPreview(preview: constructionPreview, context: &context, canvasSize: size, toScreen: toScreen)
            }

            if let draftMathObject {
                drawDraftPreview(
                    draftMathObject,
                    context: &context,
                    toScreen: toScreen
                )
            }

            let parameterValues = Dictionary(
                uniqueKeysWithValues: objects.compactMap { object -> (String, Double)? in
                    guard object.type == .parameter, let value = object.parameterValue else { return nil }
                    return (object.name, value)
                }
            )

            for object in objects where object.isVisible && isGeometryObjectRenderable(object) {
                if object.type == .circle,
                   let circle = PlaneGeometryResolver.circleGeometry(for: object, in: objects) {
                    drawGeometryCircle(
                        center: circle.center,
                        radius: circle.radius,
                        context: &context,
                        toScreen: toScreen,
                        color: ColorToken.resolvedColor(from: object.style.colorToken),
                        style: object.style,
                        opacity: object.style.opacity,
                        selected: object.id == selectedObjectID
                    )
                    continue
                }
                if object.type == .arc,
                   let arc = PlaneGeometryResolver.arcGeometry(for: object, in: objects) {
                    drawGeometryArc(
                        center: arc.center,
                        radius: arc.radius,
                        startAngle: arc.startAngle,
                        endAngle: arc.endAngle,
                        context: &context,
                        toScreen: toScreen,
                        color: ColorToken.resolvedColor(from: object.style.colorToken),
                        style: object.style,
                        opacity: object.style.opacity,
                        selected: object.id == selectedObjectID
                    )
                    continue
                }
                if let semanticSegments = semanticPlotSegments(for: object, canvasSize: size) {
                    drawPlotSegments(
                        semanticSegments,
                        context: &context,
                        toScreen: toScreen,
                        color: ColorToken.resolvedColor(from: object.style.colorToken),
                        style: object.style,
                        opacity: object.style.opacity,
                        selected: object.id == selectedObjectID
                    )
                    continue
                }
                guard let analysis = object.expression.algebraAnalysis else { continue }
                let color = ColorToken.resolvedColor(from: object.style.colorToken)
                drawAlgebraObject(
                    analysis: analysis,
                    context: &context,
                    size: size,
                    toScreen: toScreen,
                    color: color,
                    style: object.style,
                    opacity: object.style.opacity,
                    selected: object.id == selectedObjectID,
                    parameterValues: parameterValues
                )
            }

            for segment in objects where segment.type == .segment && segment.isVisible && isGeometryObjectRenderable(segment) {
                guard let endpoints = PlaneGeometryResolver.segmentEndpoints(for: segment, in: objects) else { continue }
                drawSegment(
                    context: &context,
                    a: toScreen(endpoints.0.x, endpoints.0.y),
                    b: toScreen(endpoints.1.x, endpoints.1.y),
                    color: ColorToken.resolvedColor(from: segment.style.colorToken),
                    style: segment.style,
                    opacity: segment.style.opacity,
                    selected: segment.id == selectedObjectID
                )
            }

            let visibleRect = canvasState.visibleWorldRect(in: size)
            for line in objects where line.type == .line && line.isVisible && isGeometryObjectRenderable(line) {
                guard let endpoints = PlaneGeometryResolver.linePoints(for: line, in: objects),
                      let clipped = PlaneLineClipping.clipInfiniteLine(
                        pointA: endpoints.0,
                        pointB: endpoints.1,
                        visibleWorldRect: visibleRect
                      ) else { continue }
                drawSegment(
                    context: &context,
                    a: toScreen(clipped.0.x, clipped.0.y),
                    b: toScreen(clipped.1.x, clipped.1.y),
                    color: ColorToken.resolvedColor(from: line.style.colorToken),
                    style: line.style,
                    opacity: line.style.opacity,
                    selected: line.id == selectedObjectID
                )
            }

            for ray in objects where ray.type == .ray && ray.isVisible && isGeometryObjectRenderable(ray) {
                guard let endpoints = PlaneGeometryResolver.rayPoints(for: ray, in: objects),
                      let clipped = PlaneLineClipping.clipRay(
                        start: endpoints.0,
                        through: endpoints.1,
                        visibleWorldRect: visibleRect
                      ) else { continue }
                drawSegment(
                    context: &context,
                    a: toScreen(clipped.0.x, clipped.0.y),
                    b: toScreen(clipped.1.x, clipped.1.y),
                    color: ColorToken.resolvedColor(from: ray.style.colorToken),
                    style: ray.style,
                    opacity: ray.style.opacity,
                    selected: ray.id == selectedObjectID
                )
            }

            for point in objects where point.type == .point && point.isVisible && isGeometryObjectRenderable(point) {
                guard let p = PlaneGeometryResolver.pointPosition(for: point) else { continue }
                let color = ColorToken.resolvedColor(from: point.style.colorToken, fallback: .yellowOrange)
                drawPoint(
                    context: &context,
                    at: toScreen(p.x, p.y),
                    label: point.name,
                    color: color,
                    style: point.style,
                    opacity: point.style.opacity,
                    selected: point.id == selectedObjectID
                )
            }
        }
    }

    private func drawAlgebraObject(
        analysis: AlgebraAnalysisResult,
        context: inout GraphicsContext,
        size: CGSize,
        toScreen: (Double, Double) -> CGPoint,
        color: Color,
        style: MathStyle,
        opacity: Double,
        selected: Bool,
        parameterValues: [String: Double]
    ) {
        if analysis.plotStrategy == .parametric, let rewriteInfo = analysis.rewriteInfo {
            drawParametric(
                rewriteInfo.curve,
                context: &context,
                size: size,
                toScreen: toScreen,
                color: color,
                style: style,
                opacity: opacity,
                selected: selected,
                parameterValues: parameterValues
            )
            return
        }

        switch analysis.classification.kind {
        case .explicitY:
            guard let expression = analysis.classification.renderExpression else { return }
            drawExplicitY(
                expression,
                context: &context,
                size: size,
                toScreen: toScreen,
                color: color,
                style: style,
                opacity: opacity,
                selected: selected,
                parameterValues: parameterValues
            )
        case .explicitX:
            guard let expression = analysis.classification.renderExpression else { return }
            drawExplicitX(
                expression,
                context: &context,
                size: size,
                toScreen: toScreen,
                color: color,
                style: style,
                opacity: opacity,
                selected: selected,
                parameterValues: parameterValues
            )
        case .horizontalLine:
            guard let y = analysis.classification.centerY else { return }
            drawSegment(context: &context, a: toScreen(-1000, y), b: toScreen(1000, y), color: color, style: style, opacity: opacity, selected: selected)
        case .verticalLine:
            guard let x = analysis.classification.centerX else { return }
            drawSegment(context: &context, a: toScreen(x, -1000), b: toScreen(x, 1000), color: color, style: style, opacity: opacity, selected: selected)
        case .circle, .ellipse:
            drawEllipse(analysis.classification, context: &context, toScreen: toScreen, color: color, style: style, opacity: opacity, selected: selected)
        case .superellipse, .hyperbola, .parabola, .implicitPlaneCurve, .unsupported:
            break
        }
    }

    private func isGeometryObjectRenderable(_ object: MathObject) -> Bool {
        guard object.geometryDependency != nil else { return true }
        return (object.geometryDefinitionStatus ?? .defined) == .defined
    }

    private func drawParametric(
        _ curve: ParametricCurveDefinition,
        context: inout GraphicsContext,
        size: CGSize,
        toScreen: (Double, Double) -> CGPoint,
        color: Color,
        style: MathStyle,
        opacity: Double,
        selected: Bool,
        parameterValues: [String: Double]
    ) {
        let segments = ParametricCurveSampler.sample(curve, viewport: canvasState, canvasSize: size, parameterValues: parameterValues)

        for segment in segments where segment.points.count > 1 {
            var path = Path()
            path.move(to: toScreen(segment.points[0].x, segment.points[0].y))
            for point in segment.points.dropFirst() {
                path.addLine(to: toScreen(point.x, point.y))
            }
            let lineWidth = styledLineWidth(base: style.lineWidth, selected: selected)
            if style.lineStyle == .dashed {
                context.stroke(path, with: .color(color.opacity(0.9 * opacity)), style: StrokeStyle(lineWidth: lineWidth, dash: [6, 6]))
            } else {
                context.stroke(path, with: .color(color.opacity(0.9 * opacity)), lineWidth: lineWidth)
            }
            if selected {
                context.stroke(path, with: .color(color.opacity(0.18)), lineWidth: 8)
            }
        }
    }

    private func drawExplicitY(
        _ expression: AlgebraExpression,
        context: inout GraphicsContext,
        size: CGSize,
        toScreen: (Double, Double) -> CGPoint,
        color: Color,
        style: MathStyle,
        opacity: Double,
        selected: Bool,
        parameterValues: [String: Double]
    ) {
        let rect = canvasState.visibleWorldRect(in: size)
        let samples = min(2600, max(320, Int(size.width / 1.4)))
        let segments = PlaneLegacyExplicitSampling.sampleExplicitY(
            expression,
            visibleWorldRect: rect,
            samples: samples,
            parameterValues: parameterValues
        )
        drawPlotSegments(
            segments,
            context: &context,
            toScreen: toScreen,
            color: color,
            style: style,
            opacity: opacity,
            selected: selected
        )
    }

    private func drawExplicitX(
        _ expression: AlgebraExpression,
        context: inout GraphicsContext,
        size: CGSize,
        toScreen: (Double, Double) -> CGPoint,
        color: Color,
        style: MathStyle,
        opacity: Double,
        selected: Bool,
        parameterValues: [String: Double]
    ) {
        let rect = canvasState.visibleWorldRect(in: size)
        let samples = min(2600, max(320, Int(size.height / 1.4)))
        let segments = PlaneLegacyExplicitSampling.sampleExplicitX(
            expression,
            visibleWorldRect: rect,
            samples: samples,
            parameterValues: parameterValues
        )
        drawPlotSegments(
            segments,
            context: &context,
            toScreen: toScreen,
            color: color,
            style: style,
            opacity: opacity,
            selected: selected
        )
    }

    private func drawEllipse(
        _ classification: AlgebraClassification,
        context: inout GraphicsContext,
        toScreen: (Double, Double) -> CGPoint,
        color: Color,
        style: MathStyle,
        opacity: Double,
        selected: Bool
    ) {
        let cx = classification.centerX ?? 0
        let cy = classification.centerY ?? 0
        let rx = classification.radiusX ?? classification.radius ?? 1
        let ry = classification.radiusY ?? classification.radius ?? 1
        var path = Path()

        for index in 0...160 {
            let angle = Double(index) / 160 * 2 * Double.pi
            let point = toScreen(cx + rx * cos(angle), cy + ry * sin(angle))
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        let lineWidth = styledLineWidth(base: style.lineWidth, selected: selected)
        if style.lineStyle == .dashed {
            context.stroke(path, with: .color(color.opacity(0.9 * opacity)), style: StrokeStyle(lineWidth: lineWidth, dash: [6, 6]))
        } else {
            context.stroke(path, with: .color(color.opacity(0.9 * opacity)), lineWidth: lineWidth)
        }
    }

    private func drawGeometryCircle(
        center: WorldPoint,
        radius: Double,
        context: inout GraphicsContext,
        toScreen: (Double, Double) -> CGPoint,
        color: Color,
        style: MathStyle,
        opacity: Double,
        selected: Bool
    ) {
        guard radius.isFinite, radius > 0 else { return }
        var path = Path()
        for index in 0...160 {
            let angle = Double(index) / 160 * 2 * Double.pi
            let point = toScreen(
                center.x + radius * cos(angle),
                center.y + radius * sin(angle)
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        let lineWidth = styledLineWidth(base: style.lineWidth, selected: selected)
        if style.lineStyle == .dashed {
            context.stroke(path, with: .color(color.opacity(0.9 * opacity)), style: StrokeStyle(lineWidth: lineWidth, dash: [6, 6]))
        } else {
            context.stroke(path, with: .color(color.opacity(0.9 * opacity)), lineWidth: lineWidth)
        }
        if selected {
            context.stroke(path, with: .color(color.opacity(0.2)), lineWidth: lineWidth + 4)
        }
    }

    private func drawPreview(
        preview: PlaneConstructionPreview,
        context: inout GraphicsContext,
        canvasSize: CGSize,
        toScreen: (Double, Double) -> CGPoint
    ) {
        switch preview {
        case .temporarySegment(let start, let current):
            let a = toScreen(start.x, start.y)
            let b = toScreen(current.x, current.y)
            drawSegment(context: &context, a: a, b: b, color: Color.blue.opacity(0.55), selected: false, dashed: true)
        case .temporaryLine(let pointA, let pointB):
            let visibleRect = canvasState.visibleWorldRect(in: canvasSize)
            guard let clipped = PlaneLineClipping.clipInfiniteLine(
                pointA: pointA,
                pointB: pointB,
                visibleWorldRect: visibleRect
            ) else { return }
            let a = toScreen(clipped.0.x, clipped.0.y)
            let b = toScreen(clipped.1.x, clipped.1.y)
            drawSegment(context: &context, a: a, b: b, color: Color.blue.opacity(0.55), selected: false, dashed: true)
        case .temporaryRay(let start, let through):
            let visibleRect = canvasState.visibleWorldRect(in: canvasSize)
            guard let clipped = PlaneLineClipping.clipRay(
                start: start,
                through: through,
                visibleWorldRect: visibleRect
            ) else { return }
            let a = toScreen(clipped.0.x, clipped.0.y)
            let b = toScreen(clipped.1.x, clipped.1.y)
            drawSegment(context: &context, a: a, b: b, color: Color.purple.opacity(0.58), selected: false, dashed: true)
        case .temporaryCircle(let center, let currentRadiusPoint):
            let dx = currentRadiusPoint.x - center.x
            let dy = currentRadiusPoint.y - center.y
            let radius = (dx * dx + dy * dy).squareRoot()
            guard radius.isFinite, radius > 0 else { return }

            var path = Path()
            for index in 0...96 {
                let angle = Double(index) / 96 * 2 * Double.pi
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)
                let p = toScreen(x, y)
                if index == 0 {
                    path.move(to: p)
                } else {
                    path.addLine(to: p)
                }
            }
            context.stroke(
                path,
                with: .color(Color.green.opacity(0.65)),
                style: StrokeStyle(lineWidth: 2, dash: [7, 5])
            )
        case .temporaryArc(let pointA, let pointB, let pointC):
            guard let arc = PlaneGeometryResolver.arcFromThreePoints(pointA, pointB, pointC) else { return }
            let sweep = abs(arc.endAngle - arc.startAngle)
            guard sweep > 0.001 else { return }
            let segments = max(20, Int(sweep / (2 * .pi) * 160))
            var path = Path()
            for index in 0...segments {
                let t = Double(index) / Double(segments)
                let angle = arc.startAngle + t * (arc.endAngle - arc.startAngle)
                let p = toScreen(
                    arc.center.x + arc.radius * cos(angle),
                    arc.center.y + arc.radius * sin(angle)
                )
                if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.stroke(
                path,
                with: .color(Color.green.opacity(0.65)),
                style: StrokeStyle(lineWidth: 2, dash: [7, 5])
            )

        case .temporaryIntersections(let points):
            for point in points {
                let screen = toScreen(point.x, point.y)
                let r: CGFloat = 4.5
                let rect = CGRect(x: screen.x - r, y: screen.y - r, width: r * 2, height: r * 2)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color.accentColor.opacity(0.30))
                )
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(Color.accentColor.opacity(0.90)),
                    lineWidth: 1.3
                )
            }
        }
    }

    private func drawDraftPreview(
        _ draft: DraftMathObject,
        context: inout GraphicsContext,
        toScreen: (Double, Double) -> CGPoint
    ) {
        let segments = draft.previewSamples.isEmpty ? draft.lastValidPreviewSamples : draft.previewSamples
        guard !segments.isEmpty else { return }

        for segment in segments where segment.points.count > 1 {
            var path = Path()
            path.move(to: toScreen(segment.points[0].x, segment.points[0].y))
            for point in segment.points.dropFirst() {
                path.addLine(to: toScreen(point.x, point.y))
            }
            context.stroke(
                path,
                with: .color(Color.cyan.opacity(0.62)),
                style: StrokeStyle(lineWidth: 2, dash: [7, 5])
            )
        }

        for segment in segments where segment.points.count == 1 {
            let p = segment.points[0]
            let screen = toScreen(p.x, p.y)
            let r: CGFloat = 4.5
            let rect = CGRect(x: screen.x - r, y: screen.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(Color.cyan.opacity(0.82)))
        }
    }

    private func drawGeometryArc(
        center: WorldPoint,
        radius: Double,
        startAngle: Double,
        endAngle: Double,
        context: inout GraphicsContext,
        toScreen: (Double, Double) -> CGPoint,
        color: Color,
        style: MathStyle,
        opacity: Double,
        selected: Bool
    ) {
        guard radius.isFinite, radius > 0 else { return }
        let sweep = abs(endAngle - startAngle)
        guard sweep > 0.001 else { return }
        let segments = max(20, Int(sweep / (2 * .pi) * 160))
        var path = Path()
        for index in 0...segments {
            let t = Double(index) / Double(segments)
            let angle = startAngle + t * (endAngle - startAngle)
            let point = toScreen(
                center.x + radius * cos(angle),
                center.y + radius * sin(angle)
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        let lineWidth = styledLineWidth(base: style.lineWidth, selected: selected)
        if style.lineStyle == .dashed {
            context.stroke(path, with: .color(color.opacity(opacity)), style: StrokeStyle(lineWidth: lineWidth, dash: [6, 3]))
        } else {
            context.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lineWidth)
        }
        if selected {
            context.stroke(path, with: .color(color.opacity(0.2)), lineWidth: lineWidth + 4)
        }
    }

    private func drawPlotSegments(
        _ segments: [PlotSegment],
        context: inout GraphicsContext,
        toScreen: (Double, Double) -> CGPoint,
        color: Color,
        style: MathStyle,
        opacity: Double,
        selected: Bool
    ) {
        for segment in segments where segment.points.count > 1 {
            var path = Path()
            path.move(to: toScreen(segment.points[0].x, segment.points[0].y))
            for point in segment.points.dropFirst() {
                path.addLine(to: toScreen(point.x, point.y))
            }
            let lineWidth = styledLineWidth(base: style.lineWidth, selected: selected)
            if style.lineStyle == .dashed {
                context.stroke(path, with: .color(color.opacity(0.9 * opacity)), style: StrokeStyle(lineWidth: lineWidth, dash: [6, 6]))
            } else {
                context.stroke(path, with: .color(color.opacity(0.9 * opacity)), lineWidth: lineWidth)
            }
            if selected {
                context.stroke(path, with: .color(color.opacity(0.18)), lineWidth: 8)
            }
        }

        for segment in segments where segment.points.count == 1 {
            let p = segment.points[0]
            drawPoint(
                context: &context,
                at: toScreen(p.x, p.y),
                label: "",
                color: color,
                style: style,
                opacity: opacity,
                selected: selected
            )
        }
    }

    private func semanticPlotSegments(for object: MathObject, canvasSize: CGSize) -> [PlotSegment]? {
        let parameterSymbolNames = Set(
            objects.compactMap { candidate -> String? in
                guard candidate.type == .parameter else { return nil }
                return candidate.name
            }
        )
        let resolvedWithDiagnostics = PlaneSemanticIntentResolver.resolveIntentResultWithDiagnostics(
            for: object.expression,
            parameterSymbolNames: parameterSymbolNames,
            source: .committed
        )
        guard let resolved = resolvedWithDiagnostics.resolved else {
            return nil
        }
        let intent = resolved.intent
        let policy = PlaneSemanticPreviewPolicy()
        guard policy.shouldUseSemanticPreview(for: intent) || resolved.source == .fallback else {
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

        var sampleSet = PlaneFallbackSamplingService.sampler(qualityProfile: .balanced).sample(
            intent: intent,
            xRange: xRange,
            yRange: yRange,
            viewport: viewport,
            environment: EvaluationEnvironment.variables(
                Dictionary(
                    uniqueKeysWithValues: objects.compactMap { object -> (String, Double)? in
                        guard object.type == .parameter, let value = object.parameterValue else { return nil }
                        return (object.name, value)
                    }
                )
            )
        )
        sampleSet = PlaneFallbackSamplingService.limitSegmentsIfNeeded(sampleSet, intent: intent)
        _ = PlaneFallbackSamplingService.diagnosticsForSampleSet(sampleSet, intent: intent, source: .committed)
        guard let adapted = PlaneSampleSetAdapter.adaptToPlotSegments(sampleSet), !adapted.isEmpty else {
            return nil
        }
        return adapted
    }

    private func drawSegment(
        context: inout GraphicsContext,
        a: CGPoint,
        b: CGPoint,
        color: Color,
        style: MathStyle = MathStyle(colorToken: "blue"),
        opacity: Double = 1.0,
        selected: Bool,
        dashed: Bool = false
    ) {
        var path = Path()
        path.move(to: a)
        path.addLine(to: b)

        let lineWidth = styledLineWidth(base: style.lineWidth, selected: selected)
        let shouldDash = dashed || style.lineStyle == .dashed
        if shouldDash {
            context.stroke(path, with: .color(color.opacity(opacity)), style: StrokeStyle(lineWidth: lineWidth, dash: [6, 6]))
        } else {
            context.stroke(path, with: .color(color.opacity(0.86 * opacity)), lineWidth: lineWidth)
            if selected {
                context.stroke(path, with: .color(color.opacity(0.20)), lineWidth: 8)
            }
        }
    }

    private func drawPoint(
        context: inout GraphicsContext,
        at point: CGPoint,
        label: String,
        color: Color,
        style: MathStyle = MathStyle(colorToken: "yellowOrange"),
        opacity: Double,
        selected: Bool
    ) {
        let baseRadius = max(1.5, CGFloat(style.pointSize) * 0.5)
        let r: CGFloat = selected ? baseRadius + 1 : baseRadius
        let rect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.92 * opacity)))

        if selected {
            context.stroke(Path(ellipseIn: rect.insetBy(dx: -4, dy: -4)), with: .color(color.opacity(0.25)), lineWidth: 6)
        }

        let text = Text(label)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(colorScheme == .dark ? 0.80 : 0.95))
        context.draw(text, at: CGPoint(x: point.x + 12, y: point.y - 14))
    }

    private func styledLineWidth(base: Double, selected: Bool) -> CGFloat {
        let clamped = max(0.5, min(8.0, base))
        return CGFloat(selected ? clamped + 1 : clamped)
    }
}
