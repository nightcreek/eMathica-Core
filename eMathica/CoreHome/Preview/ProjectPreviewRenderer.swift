import EMathicaDocumentKit
import CoreGraphics
import Foundation
import EMathicaMathCore

#if canImport(UIKit)
import UIKit

enum ProjectPreviewRenderer {
    struct WorldBounds {
        var minX: Double
        var maxX: Double
        var minY: Double
        var maxY: Double

        static let `default` = WorldBounds(minX: -10, maxX: 10, minY: -10, maxY: 10)

        var width: Double { maxX - minX }
        var height: Double { maxY - minY }
    }

    private struct PreviewStroke {
        var style: MathStyle
        var segments: [[WorldPoint]]
    }

    private struct PreviewPoint {
        var point: WorldPoint
        var style: MathStyle
    }

    private struct BoundsAccumulator {
        private(set) var minX = Double.greatestFiniteMagnitude
        private(set) var minY = Double.greatestFiniteMagnitude
        private(set) var maxX = -Double.greatestFiniteMagnitude
        private(set) var maxY = -Double.greatestFiniteMagnitude
        private(set) var hasFiniteValue = false

        mutating func add(_ point: WorldPoint) {
            guard point.x.isFinite, point.y.isFinite else { return }
            hasFiniteValue = true
            minX = Swift.min(minX, point.x)
            minY = Swift.min(minY, point.y)
            maxX = Swift.max(maxX, point.x)
            maxY = Swift.max(maxY, point.y)
        }

        mutating func add(_ points: [WorldPoint]) {
            for point in points {
                add(point)
            }
        }

        mutating func add(_ segments: [[WorldPoint]]) {
            for segment in segments {
                add(segment)
            }
        }

        var rect: WorldRect? {
            guard hasFiniteValue, minX.isFinite, minY.isFinite, maxX.isFinite, maxY.isFinite else { return nil }
            guard minX <= maxX, minY <= maxY else { return nil }
            return WorldRect(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
        }
    }

    private struct PreviewScene {
        var strokes: [PreviewStroke]
        var points: [PreviewPoint]
        var bounds: WorldBounds
    }

    struct PreviewWorldToPixelTransform {
        let bounds: WorldBounds
        let size: CGSize
        let scale: CGFloat
        let contentWidth: CGFloat
        let contentHeight: CGFloat
        let xOffset: CGFloat
        let yOffset: CGFloat

        init(bounds: WorldBounds, size: CGSize) {
            self.bounds = bounds
            self.size = size
            let worldWidth = max(0.000001, bounds.width)
            let worldHeight = max(0.000001, bounds.height)
            let sx = size.width / CGFloat(worldWidth)
            let sy = size.height / CGFloat(worldHeight)
            let uniformScale = max(0.000001, min(sx, sy))
            self.scale = uniformScale
            self.contentWidth = CGFloat(worldWidth) * uniformScale
            self.contentHeight = CGFloat(worldHeight) * uniformScale
            self.xOffset = (size.width - contentWidth) * 0.5
            self.yOffset = (size.height - contentHeight) * 0.5
        }

        func screenPoint(for point: WorldPoint) -> CGPoint {
            CGPoint(
                x: xOffset + CGFloat(point.x - bounds.minX) * scale,
                y: yOffset + contentHeight - CGFloat(point.y - bounds.minY) * scale
            )
        }

        func screenLength(for worldLength: Double) -> CGFloat {
            CGFloat(worldLength) * scale
        }
    }

    private static let fallbackSamplingSize = CGSize(width: 620, height: 400)

    static func renderPNGData(
        for document: EMathicaDocument,
        size: CGSize = CGSize(width: 620, height: 400)
    ) -> Data? {
        if shouldRenderSpacePreview(for: document) {
            return renderSpacePreviewPNGData(for: document, size: size)
        }

        let scene = buildScene(from: document, imageSize: size)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let transform = PreviewWorldToPixelTransform(bounds: scene.bounds, size: size)
            drawBackground(in: context.cgContext, size: size)
            drawGrid(in: context.cgContext, bounds: scene.bounds, transform: transform)
            drawAxis(in: context.cgContext, bounds: scene.bounds, transform: transform)
            drawObjects(scene, in: context.cgContext, transform: transform)
        }
        return image.pngData()
    }

    private static func shouldRenderSpacePreview(for document: EMathicaDocument) -> Bool {
        if document.metadata.calculatorType == "space" || document.moduleID == "space" {
            return true
        }
        return document.objects.contains { object in
            guard let kind = object.geometryDefinition?.kind else { return false }
            switch kind {
            case .point3D, .segment3D, .line3D, .plane3D:
                return true
            case .point, .segment, .line, .ray, .circle, .arc:
                return false
            }
        }
    }

    private static func renderSpacePreviewPNGData(
        for document: EMathicaDocument,
        size: CGSize
    ) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let viewport = SpaceViewportSize(
            width: max(1, size.width),
            height: max(1, size.height)
        )
        let camera = document.spaceCameraState ?? .default
        let scene = SpaceWireframeRenderer.buildScene(
            objects: document.objects,
            camera: camera,
            viewport: viewport
        )

        let image = renderer.image { context in
            let cg = context.cgContext
            drawSpaceBackground(in: cg, size: size)
            drawSpaceScene(scene, in: cg)
        }
        return image.pngData()
    }

    private static func drawSpaceBackground(in cg: CGContext, size: CGSize) {
        cg.setFillColor(UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0).cgColor)
        cg.fill(CGRect(origin: .zero, size: size))
    }

    private static func drawSpaceScene(_ scene: SpaceWireframeScene, in cg: CGContext) {
        // 1) plane fill
        for polygon in scene.polygons where polygon.corners.count >= 3 {
            var path = CGMutablePath()
            path.move(to: CGPoint(x: polygon.corners[0].x, y: polygon.corners[0].y))
            for corner in polygon.corners.dropFirst() {
                path.addLine(to: CGPoint(x: corner.x, y: corner.y))
            }
            path.closeSubpath()
            cg.addPath(path)
            cg.setFillColor(spaceFillColor(for: polygon.style).cgColor)
            cg.fillPath()
        }

        // 2) non-axis line work: plane borders/grid + object lines
        for segment in scene.segments where !isAxisStyle(segment.style) {
            cg.setStrokeColor(spaceStrokeColor(for: segment.style).cgColor)
            cg.setLineWidth(spaceLineWidth(for: segment.style))
            cg.move(to: CGPoint(x: segment.start.x, y: segment.start.y))
            cg.addLine(to: CGPoint(x: segment.end.x, y: segment.end.y))
            cg.strokePath()
        }

        // 3) axes last for readability
        for segment in scene.segments where isAxisStyle(segment.style) {
            cg.setStrokeColor(spaceStrokeColor(for: segment.style).cgColor)
            cg.setLineWidth(spaceLineWidth(for: segment.style))
            cg.move(to: CGPoint(x: segment.start.x, y: segment.start.y))
            cg.addLine(to: CGPoint(x: segment.end.x, y: segment.end.y))
            cg.strokePath()
        }

        // 4) points
        for point in scene.points {
            let radius: CGFloat = 2.8
            let rect = CGRect(
                x: point.projected.x - radius,
                y: point.projected.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            cg.setFillColor(spaceStrokeColor(for: point.style).cgColor)
            cg.fillEllipse(in: rect)
        }
    }

    private static func isAxisStyle(_ style: SpaceWireframeStyle) -> Bool {
        switch style {
        case .axisX, .axisY, .axisZ:
            return true
        case .object, .plane, .point:
            return false
        }
    }

    private static func spaceStrokeColor(for style: SpaceWireframeStyle) -> UIColor {
        switch style {
        case .axisX:
            return UIColor(red: 0.72, green: 0.12, blue: 0.12, alpha: 1.0)
        case .axisY:
            return UIColor(red: 0.08, green: 0.52, blue: 0.16, alpha: 1.0)
        case .axisZ:
            return UIColor(red: 0.08, green: 0.30, blue: 0.72, alpha: 1.0)
        case .plane:
            return UIColor(red: 0.10, green: 0.36, blue: 0.78, alpha: 0.85)
        case .point, .object:
            return UIColor.black.withAlphaComponent(0.88)
        }
    }

    private static func spaceFillColor(for style: SpaceWireframeStyle) -> UIColor {
        switch style {
        case .plane:
            return UIColor(red: 0.10, green: 0.36, blue: 0.78, alpha: 0.15)
        case .axisX, .axisY, .axisZ, .object, .point:
            return .clear
        }
    }

    private static func spaceLineWidth(for style: SpaceWireframeStyle) -> CGFloat {
        switch style {
        case .axisX, .axisY, .axisZ:
            return 2.2
        case .plane:
            return 1.3
        case .object:
            return 1.4
        case .point:
            return 1.0
        }
    }

    private static func drawBackground(in cg: CGContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let colors = [
            UIColor(red: 0.95, green: 0.97, blue: 1.00, alpha: 1.0).cgColor,
            UIColor(red: 0.90, green: 0.94, blue: 1.00, alpha: 1.0).cgColor
        ] as CFArray
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0, 1]
        ) else {
            cg.setFillColor(UIColor.white.cgColor)
            cg.fill(rect)
            return
        }
        cg.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: size.width, y: size.height),
            options: []
        )
    }

    private static func drawGrid(in cg: CGContext, bounds: WorldBounds, transform: PreviewWorldToPixelTransform) {
        cg.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        cg.setLineWidth(1)
        let targetStep = max(0.000001, bounds.width / 8)
        let majorStep = niceGridStep(for: targetStep)

        var x = floor(bounds.minX / majorStep) * majorStep
        while x <= bounds.maxX {
            let top = transform.screenPoint(for: WorldPoint(x: x, y: bounds.maxY))
            let bottom = transform.screenPoint(for: WorldPoint(x: x, y: bounds.minY))
            cg.move(to: top)
            cg.addLine(to: bottom)
            x += majorStep
        }

        var y = floor(bounds.minY / majorStep) * majorStep
        while y <= bounds.maxY {
            let left = transform.screenPoint(for: WorldPoint(x: bounds.minX, y: y))
            let right = transform.screenPoint(for: WorldPoint(x: bounds.maxX, y: y))
            cg.move(to: left)
            cg.addLine(to: right)
            y += majorStep
        }
        cg.strokePath()
    }

    private static func drawAxis(in cg: CGContext, bounds: WorldBounds, transform: PreviewWorldToPixelTransform) {
        cg.setStrokeColor(UIColor.black.withAlphaComponent(0.30).cgColor)
        cg.setLineWidth(1.5)
        if bounds.minY <= 0, bounds.maxY >= 0 {
            let start = transform.screenPoint(for: WorldPoint(x: bounds.minX, y: 0))
            let end = transform.screenPoint(for: WorldPoint(x: bounds.maxX, y: 0))
            cg.move(to: start)
            cg.addLine(to: end)
            cg.strokePath()
        }
        if bounds.minX <= 0, bounds.maxX >= 0 {
            let start = transform.screenPoint(for: WorldPoint(x: 0, y: bounds.minY))
            let end = transform.screenPoint(for: WorldPoint(x: 0, y: bounds.maxY))
            cg.move(to: start)
            cg.addLine(to: end)
            cg.strokePath()
        }
    }

    private static func drawObjects(_ scene: PreviewScene, in cg: CGContext, transform: PreviewWorldToPixelTransform) {
        for stroke in scene.strokes {
            let uiColor = color(for: stroke.style.colorToken).withAlphaComponent(
                CGFloat(max(0, min(1, stroke.style.opacity)))
            )
            cg.setStrokeColor(uiColor.cgColor)
            cg.setLineWidth(CGFloat(max(0.5, min(8.0, stroke.style.lineWidth))))
            if stroke.style.lineStyle == .dashed {
                cg.setLineDash(phase: 0, lengths: [6, 6])
            } else {
                cg.setLineDash(phase: 0, lengths: [])
            }
            for segment in stroke.segments where segment.count >= 2 {
                guard let first = segment.first else { continue }
                cg.move(to: transform.screenPoint(for: first))
                for point in segment.dropFirst() {
                    cg.addLine(to: transform.screenPoint(for: point))
                }
                cg.strokePath()
            }
        }
        cg.setLineDash(phase: 0, lengths: [])

        for point in scene.points {
            let center = transform.screenPoint(for: point.point)
            let radius = thumbnailPointRadius(from: point.style.pointSize)
            let rect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            let fill = color(for: point.style.colorToken).withAlphaComponent(
                CGFloat(max(0, min(1, point.style.opacity)))
            )
            cg.setFillColor(fill.cgColor)
            cg.fillEllipse(in: rect)
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.88).cgColor)
            cg.setLineWidth(1)
            cg.strokeEllipse(in: rect)
        }
    }

    static func thumbnailPointRadius(from stylePointSize: Double) -> CGFloat {
        let sanitizedDiameter = max(3.0, min(16.0, stylePointSize))
        let baseRadius = CGFloat(sanitizedDiameter * 0.5)
        return min(max(baseRadius, 2.5), 6.0)
    }

    private static func buildScene(from document: EMathicaDocument, imageSize: CGSize) -> PreviewScene {
        let samplingBounds = thumbnailSeedBounds(for: document, imageSize: imageSize)
        let draft = buildSceneDraft(from: document, imageSize: imageSize, samplingBounds: samplingBounds)
        let fittedBounds = thumbnailBounds(from: draft.contentBounds, imageSize: imageSize) ?? samplingBounds
        if bounds(samplingBounds, isApproximatelyEqualTo: fittedBounds) {
            return PreviewScene(strokes: draft.strokes, points: draft.points, bounds: fittedBounds)
        }

        let rerendered = buildSceneDraft(from: document, imageSize: imageSize, samplingBounds: fittedBounds)
        let finalBounds = thumbnailBounds(from: rerendered.contentBounds, imageSize: imageSize) ?? fittedBounds
        return PreviewScene(strokes: rerendered.strokes, points: rerendered.points, bounds: finalBounds)
    }

    internal static func thumbnailBounds(for document: EMathicaDocument, imageSize: CGSize = fallbackSamplingSize) -> WorldBounds {
        buildScene(from: document, imageSize: imageSize).bounds
    }

    private static func buildSceneDraft(
        from document: EMathicaDocument,
        imageSize: CGSize,
        samplingBounds: WorldBounds
    ) -> (strokes: [PreviewStroke], points: [PreviewPoint], contentBounds: WorldRect?) {
        let visibleObjects = document.objects.filter {
            $0.isVisible
            && $0.type != .parameter
            && $0.type != .parameterGroup
            && isRenderableGeometryObject($0)
        }
        let bounds = samplingBounds
        let rect = WorldRect(minX: bounds.minX, minY: bounds.minY, maxX: bounds.maxX, maxY: bounds.maxY)
        var strokes: [PreviewStroke] = []
        var points: [PreviewPoint] = []
        var contentBounds = BoundsAccumulator()

        let parameterEnvironment = EvaluationEnvironment.variables(
            Dictionary(uniqueKeysWithValues: document.objects.compactMap { object -> (String, Double)? in
                guard object.type == .parameter, let value = object.parameterValue else { return nil }
                return (object.name, value)
            })
        )
        let xRange = SamplingRange(lower: bounds.minX, upper: bounds.maxX)
        let yRange = SamplingRange(lower: bounds.minY, upper: bounds.maxY)
        let viewport = SamplingViewport2D(
            xRange: xRange,
            yRange: yRange,
            pixelWidth: max(1, imageSize.width),
            pixelHeight: max(1, imageSize.height)
        )

        for object in visibleObjects {
            if object.type == .point, let p = PlaneGeometryResolver.pointPosition(for: object), p.x.isFinite, p.y.isFinite {
                points.append(PreviewPoint(point: p, style: object.style.sanitized()))
                contentBounds.add(p)
                continue
            }

            if let segments = geometrySegments(for: object, in: visibleObjects, visibleWorldRect: rect), !segments.isEmpty {
                strokes.append(PreviewStroke(style: object.style.sanitized(), segments: segments))
                if object.type != .line && object.type != .ray {
                    contentBounds.add(segments)
                }
                continue
            }

            if object.type == .function || object.type == .circle {
                if let segments = semanticSegments(
                    for: object,
                    allObjects: document.objects,
                    xRange: xRange,
                    yRange: yRange,
                    viewport: viewport,
                    environment: parameterEnvironment
                ), !segments.isEmpty {
                    strokes.append(PreviewStroke(style: object.style.sanitized(), segments: segments))
                    contentBounds.add(segments)
                    continue
                }

                if let segments = legacyAlgebraSegments(
                    for: object,
                    allObjects: document.objects,
                    visibleWorldRect: rect
                ), !segments.isEmpty {
                    strokes.append(PreviewStroke(style: object.style.sanitized(), segments: segments))
                    contentBounds.add(segments)
                    continue
                }
            }
        }

        return (strokes: strokes, points: points, contentBounds: contentBounds.rect)
    }

    private static func isRenderableGeometryObject(_ object: MathObject) -> Bool {
        guard object.geometryDependency != nil else { return true }
        return (object.geometryDefinitionStatus ?? .defined) == .defined
    }

    private static func geometrySegments(
        for object: MathObject,
        in objects: [MathObject],
        visibleWorldRect: WorldRect
    ) -> [[WorldPoint]]? {
        switch object.type {
        case .segment:
            guard let endpoints = PlaneGeometryResolver.segmentEndpoints(for: object, in: objects) else { return nil }
            return [[endpoints.0, endpoints.1]]
        case .line:
            guard let points = PlaneGeometryResolver.linePoints(for: object, in: objects),
                  let clipped = PlaneLineClipping.clipInfiniteLine(
                    pointA: points.0,
                    pointB: points.1,
                    visibleWorldRect: visibleWorldRect
                  ) else { return nil }
            return [[clipped.0, clipped.1]]
        case .ray:
            guard let points = PlaneGeometryResolver.rayPoints(for: object, in: objects),
                  let clipped = PlaneLineClipping.clipRay(
                    start: points.0,
                    through: points.1,
                    visibleWorldRect: visibleWorldRect
                  ) else { return nil }
            return [[clipped.0, clipped.1]]
        case .circle:
            guard let circle = PlaneGeometryResolver.circleGeometry(for: object, in: objects) else { return nil }
            return [sampleCircle(center: circle.center, radius: circle.radius)]
        case .arc:
            guard let arc = PlaneGeometryResolver.arcGeometry(for: object, in: objects) else { return nil }
            return [sampleArc(center: arc.center, radius: arc.radius,
                              startAngle: arc.startAngle, endAngle: arc.endAngle)]
        case .function, .point, .parameter, .parameterGroup:
            return nil
        }
    }

    private static func thumbnailSeedBounds(for document: EMathicaDocument, imageSize: CGSize) -> WorldBounds {
        let visibleObjects = document.objects.filter {
            $0.isVisible
            && $0.type != .parameter
            && $0.type != .parameterGroup
            && isRenderableGeometryObject($0)
        }
        var accumulator = BoundsAccumulator()
        for object in visibleObjects {
            if object.type == .point, let point = PlaneGeometryResolver.pointPosition(for: object) {
                accumulator.add(point)
                continue
            }
            switch object.type {
            case .segment:
                if let endpoints = PlaneGeometryResolver.segmentEndpoints(for: object, in: visibleObjects) {
                    accumulator.add([endpoints.0, endpoints.1])
                }
            case .circle:
                if let circle = PlaneGeometryResolver.circleGeometry(for: object, in: visibleObjects) {
                    accumulator.add(sampleCircle(center: circle.center, radius: circle.radius, samples: 48))
                }
            case .arc:
                if let arc = PlaneGeometryResolver.arcGeometry(for: object, in: visibleObjects) {
                    accumulator.add(sampleArc(
                        center: arc.center,
                        radius: arc.radius,
                        startAngle: arc.startAngle,
                        endAngle: arc.endAngle
                    ))
                }
            case .line, .ray, .function, .point, .parameter, .parameterGroup:
                continue
            }
        }
        return thumbnailBounds(from: accumulator.rect, imageSize: imageSize) ?? .default
    }

    private static func thumbnailBounds(from contentBounds: WorldRect?, imageSize: CGSize) -> WorldBounds? {
        guard let contentBounds,
              contentBounds.minX.isFinite,
              contentBounds.minY.isFinite,
              contentBounds.maxX.isFinite,
              contentBounds.maxY.isFinite,
              contentBounds.minX <= contentBounds.maxX,
              contentBounds.minY <= contentBounds.maxY else {
            return nil
        }

        let safeImageWidth = max(1.0, imageSize.width)
        let safeImageHeight = max(1.0, imageSize.height)
        let imageAspect = safeImageWidth / safeImageHeight
        let centerX = (contentBounds.minX + contentBounds.maxX) * 0.5
        let centerY = (contentBounds.minY + contentBounds.maxY) * 0.5
        let paddedWidth = max(4.0, contentBounds.maxX - contentBounds.minX) * 1.18
        let paddedHeight = max(4.0, contentBounds.maxY - contentBounds.minY) * 1.18

        var width = paddedWidth
        var height = paddedHeight
        let contentAspect = width / max(0.000001, height)
        if contentAspect < imageAspect {
            width = height * imageAspect
        } else if contentAspect > imageAspect {
            height = width / imageAspect
        }

        guard width.isFinite, height.isFinite, width > 0, height > 0 else { return nil }
        return WorldBounds(
            minX: centerX - width * 0.5,
            maxX: centerX + width * 0.5,
            minY: centerY - height * 0.5,
            maxY: centerY + height * 0.5
        )
    }

    private static func bounds(_ lhs: WorldBounds, isApproximatelyEqualTo rhs: WorldBounds, epsilon: Double = 0.001) -> Bool {
        abs(lhs.minX - rhs.minX) <= epsilon
            && abs(lhs.maxX - rhs.maxX) <= epsilon
            && abs(lhs.minY - rhs.minY) <= epsilon
            && abs(lhs.maxY - rhs.maxY) <= epsilon
    }

    private static func makeThumbnailScene(from document: EMathicaDocument, imageSize: CGSize) -> PreviewScene {
        let seedBounds = thumbnailSeedBounds(for: document, imageSize: imageSize)
        let firstDraft = buildSceneDraft(from: document, imageSize: imageSize, samplingBounds: seedBounds)
        let firstFit = thumbnailBounds(from: firstDraft.contentBounds, imageSize: imageSize) ?? seedBounds
        guard !bounds(seedBounds, isApproximatelyEqualTo: firstFit) else {
            return PreviewScene(strokes: firstDraft.strokes, points: firstDraft.points, bounds: firstFit)
        }

        let secondDraft = buildSceneDraft(from: document, imageSize: imageSize, samplingBounds: firstFit)
        let secondFit = thumbnailBounds(from: secondDraft.contentBounds, imageSize: imageSize) ?? firstFit
        return PreviewScene(strokes: secondDraft.strokes, points: secondDraft.points, bounds: secondFit)
    }

    private static func sampleCircle(center: WorldPoint, radius: Double, samples: Int = 180) -> [WorldPoint] {
        guard radius.isFinite, radius > 0 else { return [] }
        var points: [WorldPoint] = []
        points.reserveCapacity(samples + 1)
        for i in 0...samples {
            let theta = (Double(i) / Double(samples)) * 2 * .pi
            points.append(
                WorldPoint(
                    x: center.x + radius * cos(theta),
                    y: center.y + radius * sin(theta)
                )
            )
        }
        return points
    }

    private static func sampleArc(
        center: WorldPoint,
        radius: Double,
        startAngle: Double,
        endAngle: Double
    ) -> [WorldPoint] {
        guard radius.isFinite, radius > 0 else { return [] }
        let sweep = abs(endAngle - startAngle)
        guard sweep > 0.001 else { return [] }
        let samples = max(20, Int(sweep / (2 * .pi) * 180))
        var points: [WorldPoint] = []
        points.reserveCapacity(samples + 1)
        for i in 0...samples {
            let t = Double(i) / Double(samples)
            let angle = startAngle + t * (endAngle - startAngle)
            points.append(WorldPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            ))
        }
        return points
    }

    private static func semanticSegments(
        for object: MathObject,
        allObjects: [MathObject],
        xRange: SamplingRange,
        yRange: SamplingRange,
        viewport: SamplingViewport2D,
        environment: EvaluationEnvironment
    ) -> [[WorldPoint]]? {
        let parameterSymbolNames = Set(
            allObjects.compactMap { candidate -> String? in
                guard candidate.type == .parameter else { return nil }
                return candidate.name
            }
        )
        guard let resolved = PlaneSemanticIntentResolver.resolveIntentResult(
            for: object.expression,
            parameterSymbolNames: parameterSymbolNames
        ) else {
            return nil
        }

        var sampleSet = PlaneFallbackSamplingService.sampler(qualityProfile: .balanced).sample(
            intent: resolved.intent,
            xRange: xRange,
            yRange: yRange,
            viewport: viewport,
            environment: environment
        )
        sampleSet = PlaneFallbackSamplingService.limitSegmentsIfNeeded(sampleSet, intent: resolved.intent)
        guard let adapted = PlaneSampleSetAdapter.adaptToPlotSegments(sampleSet), !adapted.isEmpty else {
            return nil
        }
        let segments = adapted.map { $0.points }.filter { $0.count >= 2 }
        return segments.isEmpty ? nil : segments
    }

    private static func legacyAlgebraSegments(
        for object: MathObject,
        allObjects: [MathObject],
        visibleWorldRect: WorldRect
    ) -> [[WorldPoint]]? {
        guard let analysis = analysisResult(for: object) else { return nil }
        let parameters = Dictionary(
            uniqueKeysWithValues: allObjects.compactMap { object -> (String, Double)? in
                guard object.type == .parameter, let value = object.parameterValue else { return nil }
                return (object.name, value)
            }
        )

        if analysis.plotStrategy == .parametric, let curve = analysis.rewriteInfo?.curve {
            let points = sampleParametric(curve, parameterValues: parameters)
            return points.isEmpty ? nil : [points]
        }
        if analysis.plotStrategy == .implicit {
            return sampleImplicit(relation: analysis.simplifiedRelation, range: visibleWorldRect)
        }

        guard let expression = analysis.classification.renderExpression else { return nil }
        switch analysis.classification.kind {
        case .explicitY:
            return sampleExplicitY(expression, visibleWorldRect: visibleWorldRect, range: visibleWorldRect.minX...visibleWorldRect.maxX, samples: 220, parameterValues: parameters)
        case .explicitX:
            return sampleExplicitX(expression, visibleWorldRect: visibleWorldRect, range: visibleWorldRect.minY...visibleWorldRect.maxY, samples: 220, parameterValues: parameters)
        case .circle:
            guard let centerX = analysis.classification.centerX,
                  let centerY = analysis.classification.centerY,
                  let radius = analysis.classification.radius ?? analysis.classification.radiusX ?? analysis.classification.radiusY else {
                return nil
            }
            let points = sampleCircle(center: WorldPoint(x: centerX, y: centerY), radius: radius)
            return points.isEmpty ? nil : [points]
        default:
            return nil
        }
    }

    private static func analysisResult(for object: MathObject) -> AlgebraAnalysisResult? {
        if let analysis = object.expression.algebraAnalysis {
            return analysis
        }
        let raw = object.expression.sourceExpression?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return nil }
        let input = (raw.contains("=") || raw.contains("\\begin{cases}") || raw.contains("piecewise(")) ? raw : "y=\(raw)"
        let analysis = AlgebraCore.analyzePlaneLatex(input)
        if analysis.diagnostics.contains(where: { $0.severity == .error }) {
            return nil
        }
        return analysis
    }

    private static func sampleExplicitY(
        _ expression: AlgebraExpression,
        visibleWorldRect: WorldRect,
        range: ClosedRange<Double>,
        samples: Int,
        parameterValues: [String: Double]
    ) -> [[WorldPoint]] {
        PlaneLegacyExplicitSampling
            .sampleExplicitY(
                expression,
                visibleWorldRect: visibleWorldRect,
                samples: samples,
                parameterValues: parameterValues
            )
            .map(\.points)
    }

    private static func sampleExplicitX(
        _ expression: AlgebraExpression,
        visibleWorldRect: WorldRect,
        range: ClosedRange<Double>,
        samples: Int,
        parameterValues: [String: Double]
    ) -> [[WorldPoint]] {
        PlaneLegacyExplicitSampling
            .sampleExplicitX(
                expression,
                visibleWorldRect: visibleWorldRect,
                samples: samples,
                parameterValues: parameterValues
            )
            .map(\.points)
    }

    static func legacyAlgebraSegmentsForTesting(
        for object: MathObject,
        allObjects: [MathObject] = [],
        visibleWorldRect: WorldRect = .init(minX: -10, minY: -10, maxX: 10, maxY: 10)
    ) -> [[WorldPoint]]? {
        legacyAlgebraSegments(for: object, allObjects: allObjects, visibleWorldRect: visibleWorldRect)
    }

    private static func sampleParametric(
        _ curve: ParametricCurveDefinition,
        parameterValues: [String: Double]
    ) -> [WorldPoint] {
        let samples = 220
        let range = curve.tMin...curve.tMax
        var points: [WorldPoint] = []
        points.reserveCapacity(samples + 1)
        for i in 0...samples {
            let t = range.lowerBound + (range.upperBound - range.lowerBound) * (Double(i) / Double(samples))
            guard let point = evaluateParametric(curve, t: t, parameterValues: parameterValues),
                  point.x.isFinite, point.y.isFinite else { continue }
            points.append(point)
        }
        return points
    }

    private static func evaluateParametric(
        _ curve: ParametricCurveDefinition,
        t: Double,
        parameterValues: [String: Double]
    ) -> WorldPoint? {
        switch curve.kind {
        case .circle, .ellipse:
            let rx = resolve(curve.radiusX, symbol: curve.radiusXSymbol, parameterValues: parameterValues)
            let ry = resolve(curve.radiusY, symbol: curve.radiusYSymbol, parameterValues: parameterValues)
            guard rx != 0, ry != 0 else { return nil }
            return .init(x: curve.centerX + rx * cos(t), y: curve.centerY + ry * sin(t))
        case .superellipse:
            let rx = resolve(curve.radiusX, symbol: curve.radiusXSymbol, parameterValues: parameterValues)
            let ry = resolve(curve.radiusY, symbol: curve.radiusYSymbol, parameterValues: parameterValues)
            let n = resolve(curve.exponent, symbol: curve.exponentSymbol, parameterValues: parameterValues)
            guard rx != 0, ry != 0, n > 0 else { return nil }
            let cx = cos(t)
            let sy = sin(t)
            let x = curve.centerX + rx * signedPower(cx, exponent: 2 / n)
            let y = curve.centerY + ry * signedPower(sy, exponent: 2 / n)
            return .init(x: x, y: y)
        case .hyperbolaHorizontal, .hyperbolaVertical, .parabolaHorizontal, .parabolaVertical:
            return nil
        }
    }

    private static func resolve(_ fallback: Double, symbol: String?, parameterValues: [String: Double]) -> Double {
        guard let symbol else { return fallback }
        return parameterValues[symbol] ?? fallback
    }

    private static func signedPower(_ value: Double, exponent: Double) -> Double {
        let magnitude = pow(abs(value), exponent)
        return value < 0 ? -magnitude : magnitude
    }

    private static func sampleImplicit(relation: AlgebraRelation, range: WorldRect) -> [[WorldPoint]] {
        let resolution = 96
        let dx = (range.maxX - range.minX) / Double(resolution)
        let dy = (range.maxY - range.minY) / Double(resolution)
        guard dx.isFinite, dy.isFinite, dx > 0, dy > 0 else { return [] }
        var segments: [[WorldPoint]] = []

        for i in 0..<resolution {
            for j in 0..<resolution {
                let x0 = range.minX + Double(i) * dx
                let x1 = x0 + dx
                let y0 = range.minY + Double(j) * dy
                let y1 = y0 + dy
                let corners = [
                    evaluateImplicit(relation: relation, x: x0, y: y0),
                    evaluateImplicit(relation: relation, x: x1, y: y0),
                    evaluateImplicit(relation: relation, x: x1, y: y1),
                    evaluateImplicit(relation: relation, x: x0, y: y1)
                ]
                guard corners.allSatisfy({ $0?.isFinite == true }) else { continue }
                let values = corners.compactMap { $0 }
                let hasPositive = values.contains { $0 > 0 }
                let hasNegative = values.contains { $0 < 0 }
                if hasPositive && hasNegative {
                    let center = WorldPoint(x: (x0 + x1) * 0.5, y: (y0 + y1) * 0.5)
                    segments.append([center, WorldPoint(x: center.x + dx * 0.25, y: center.y)])
                }
            }
        }

        return segments
    }

    private static func evaluateImplicit(relation: AlgebraRelation, x: Double, y: Double) -> Double? {
        let vars = ["x": x, "y": y]
        switch relation {
        case .expression(let expression):
            return AlgebraEvaluator.evaluate(expression, variables: vars)
        case .equation(let equation):
            guard let l = AlgebraEvaluator.evaluate(equation.left, variables: vars),
                  let r = AlgebraEvaluator.evaluate(equation.right, variables: vars) else {
                return nil
            }
            return l - r
        }
    }

    private static func niceGridStep(for target: Double) -> Double {
        let safe = max(0.000001, target)
        let exponent = floor(log10(safe))
        let base = pow(10.0, exponent)
        let normalized = safe / base
        let factor: Double
        if normalized <= 1 {
            factor = 1
        } else if normalized <= 2 {
            factor = 2
        } else if normalized <= 5 {
            factor = 5
        } else {
            factor = 10
        }
        return factor * base
    }

    private static func color(for token: String) -> UIColor {
        switch token {
        case "blue": return UIColor.systemBlue
        case "indigo": return UIColor.systemIndigo
        case "purple": return UIColor.systemPurple
        case "pink": return UIColor.systemPink
        case "green": return UIColor.systemGreen
        case "orange", "yellowOrange": return UIColor.systemOrange
        case "teal", "cyan": return UIColor.systemTeal
        case "red": return UIColor.systemRed
        case "white": return UIColor.white
        default: return UIColor.systemBlue
        }
    }
}
#else
enum ProjectPreviewRenderer {
    static func renderPNGData(for document: EMathicaDocument, size: CGSize = .zero) -> Data? {
        _ = document
        _ = size
        return nil
    }
}
#endif
