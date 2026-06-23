import EMathicaWorkspaceKit
import EMathicaDocumentKit
import Foundation
import CoreGraphics
import EMathicaMathCore

enum PlaneDraftPreviewService {
    #if DEBUG
    private static let semanticSamplingDebugEnabled = false
    private static let useSemanticSamplingForPreview = false
    private static let semanticSamplingComparisonEnabled = false
    #endif

    static func makeDraft(
        formulaInputState: FormulaInputState,
        document: EMathicaDocument,
        previous: DraftMathObject?,
        canvasPixelSize: CGSize? = nil,
        isCanvasInteracting: Bool = false
    ) -> DraftMathObject? {
        let source = formulaInputState.source.trimmingCharacters(in: .whitespacesAndNewlines)
        #if DEBUG
        print("[PlanePreview][DraftService] sourceRaw=\"\(formulaInputState.source)\" sourceTrimmed=\"\(source)\"")
        #endif
        guard !source.isEmpty else { return nil }

        let previewInput: String
        if source.contains("=") || source.contains("\\begin{cases}") || source.contains("piecewise(") {
            previewInput = source
        } else {
            previewInput = "y=\(source)"
        }

        let analysis = AlgebraCore.analyzePlaneLatex(previewInput)
        let parseError = analysis.diagnostics.first(where: { $0.severity == .error })?.message
        #if DEBUG
        print("[PlanePreview][DraftService] previewInput=\"\(previewInput)\" class=\(analysis.classification.kind) plot=\(analysis.plotStrategy) rewrite=\(analysis.rewriteInfo == nil ? "nil" : "\(analysis.rewriteInfo!.shapeKind)") parseError=\(parseError ?? "nil")")
        #endif
        var next = DraftMathObject(
            ast: formulaInputState.editorState,
            sourceExpression: formulaInputState.source,
            displayLatex: formulaInputState.displayLatex,
            computeExpression: formulaInputState.computeExpression,
            parseError: parseError,
            previewSamples: [],
            lastValidPreviewSamples: previous?.lastValidPreviewSamples ?? [],
            algebraAnalysis: parseError == nil ? analysis : nil,
            diagnostics: formulaInputState.semanticState.plotDiagnostics(source: .draft)
        )

        if let parseError {
            next.diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .parse,
                    severity: .error,
                    code: "algebra_parse_error",
                    message: parseError,
                    source: .draft
                )
            )
        }

        var usedSemanticPreview = false
        if parseError == nil {
            if let semanticSamples = makeDefaultSemanticPreviewSegmentsIfAvailable(
                formulaInputState: formulaInputState,
                document: document,
                canvasState: document.canvasState,
                canvasPixelSize: canvasPixelSize,
                isCanvasInteracting: isCanvasInteracting
            ) {
                usedSemanticPreview = true
                next.previewSamples = semanticSamples
                next.lastValidPreviewSamples = semanticSamples
            }
            if !usedSemanticPreview {
                let parameters = currentParameterValues(from: document)
                let samples = samplePreviewSegments(analysis: analysis, canvasState: document.canvasState, parameterValues: parameters)
                if !samples.isEmpty {
                    next.previewSamples = samples
                    next.lastValidPreviewSamples = samples
                } else {
                    next.diagnostics.append(
                        FormulaPlotDiagnostic(
                            stage: .sampling,
                            severity: .warning,
                            code: "legacy_preview_empty_samples",
                            message: "预览采样结果为空",
                            source: .draft
                        )
                    )
                }
                #if DEBUG
                let pointCount = samples.reduce(0) { $0 + $1.points.count }
                print("[PlanePreview][DraftService] sampled segments=\(samples.count) points=\(pointCount)")
                #endif
            }
            #if DEBUG
            if usedSemanticPreview {
                let pointCount = next.previewSamples.reduce(0) { $0 + $1.points.count }
                print("[PlanePreview][DraftService] sampled via semantic policy segments=\(next.previewSamples.count) points=\(pointCount)")
            }
            #endif
        }
        if next.previewSamples.isEmpty {
            next.previewSamples = next.lastValidPreviewSamples
            #if DEBUG
            print("[PlanePreview][DraftService] using lastValidPreviewSamples count=\(next.lastValidPreviewSamples.count)")
            #endif
        }

        #if DEBUG
        if semanticSamplingComparisonEnabled {
            runSemanticSamplingComparisonIfNeeded(
                formulaInputState: formulaInputState,
                document: document,
                canvasState: document.canvasState,
                legacySegments: next.previewSamples,
                canvasPixelSize: canvasPixelSize,
                isCanvasInteracting: isCanvasInteracting
            )
        }

        if useSemanticSamplingForPreview,
           let semanticSamples = makeSemanticPreviewSegmentsIfAvailable(
            formulaInputState: formulaInputState,
            document: document,
            canvasState: document.canvasState,
            canvasPixelSize: canvasPixelSize,
            isCanvasInteracting: isCanvasInteracting
           ) {
            next.previewSamples = semanticSamples
            next.lastValidPreviewSamples = semanticSamples
            print("[PlanePreview][DraftService] semantic preview override segments=\(semanticSamples.count)")
        }

        runSemanticSamplingDebugIfNeeded(
            formulaInputState: formulaInputState,
            document: document,
            canvasState: document.canvasState,
            canvasPixelSize: canvasPixelSize,
            isCanvasInteracting: isCanvasInteracting
        )
        #endif

        return next
    }

    private static func currentParameterValues(from document: EMathicaDocument) -> [String: Double] {
        Dictionary(
            uniqueKeysWithValues: document.objects.compactMap { object -> (String, Double)? in
                guard object.type == .parameter, let value = object.parameterValue else { return nil }
                return (object.name, value)
            }
        )
    }

    private static func currentParameterEnvironment(from document: EMathicaDocument) -> EvaluationEnvironment {
        EvaluationEnvironment.variables(currentParameterValues(from: document))
    }

    private static func samplePreviewSegments(
        analysis: AlgebraAnalysisResult,
        canvasState: CanvasState,
        parameterValues: [String: Double]
    ) -> [PlotSegment] {
        if analysis.plotStrategy == .parametric, let curve = analysis.rewriteInfo?.curve {
            return sampleParametric(curve, parameterValues: parameterValues)
        }
        guard let expression = analysis.classification.renderExpression else { return [] }
        switch analysis.classification.kind {
        case .explicitY:
            return sampleExplicitY(expression, canvasState: canvasState, parameterValues: parameterValues)
        case .explicitX:
            return sampleExplicitX(expression, canvasState: canvasState, parameterValues: parameterValues)
        default:
            return []
        }
    }

    private static func sampleExplicitY(
        _ expression: AlgebraExpression,
        canvasState: CanvasState,
        parameterValues: [String: Double]
    ) -> [PlotSegment] {
        let pointsPerUnit = max(0.000001, canvasState.scale)
        let halfW = 512.0 / pointsPerUnit
        let halfH = 320.0 / pointsPerUnit
        let centerX = -Double(canvasState.origin.x) / pointsPerUnit
        let centerY = Double(canvasState.origin.y) / pointsPerUnit
        let rect = WorldRect(
            minX: centerX - halfW,
            minY: centerY - halfH,
            maxX: centerX + halfW,
            maxY: centerY + halfH
        )
        return PlaneLegacyExplicitSampling.sampleExplicitY(
            expression,
            visibleWorldRect: rect,
            samples: 700,
            parameterValues: parameterValues
        )
    }

    private static func sampleExplicitX(
        _ expression: AlgebraExpression,
        canvasState: CanvasState,
        parameterValues: [String: Double]
    ) -> [PlotSegment] {
        let pointsPerUnit = max(0.000001, canvasState.scale)
        let halfW = 512.0 / pointsPerUnit
        let halfH = 320.0 / pointsPerUnit
        let centerX = -Double(canvasState.origin.x) / pointsPerUnit
        let centerY = Double(canvasState.origin.y) / pointsPerUnit
        let rect = WorldRect(
            minX: centerX - halfW,
            minY: centerY - halfH,
            maxX: centerX + halfW,
            maxY: centerY + halfH
        )
        return PlaneLegacyExplicitSampling.sampleExplicitX(
            expression,
            visibleWorldRect: rect,
            samples: 700,
            parameterValues: parameterValues
        )
    }

    private static func sampleParametric(
        _ curve: ParametricCurveDefinition,
        parameterValues: [String: Double]
    ) -> [PlotSegment] {
        let samples = 320
        let range = curve.tMin...curve.tMax
        var points: [WorldPoint] = []
        for i in 0...samples {
            let t = range.lowerBound + (range.upperBound - range.lowerBound) * (Double(i) / Double(samples))
            guard let point = evaluateParametric(curve, t: t, parameterValues: parameterValues),
                  point.x.isFinite, point.y.isFinite else { continue }
            points.append(point)
        }
        return points.isEmpty ? [] : [PlotSegment(points: points)]
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

    private static func makeDefaultSemanticPreviewSegmentsIfAvailable(
        formulaInputState: FormulaInputState,
        document: EMathicaDocument,
        canvasState: CanvasState,
        canvasPixelSize: CGSize?,
        isCanvasInteracting: Bool
    ) -> [PlotSegment]? {
        let semanticAttempt = makeSemanticSamplingAttempt(
            formulaInputState: formulaInputState,
            document: document,
            canvasState: canvasState,
            enforceDefaultPolicy: true,
            canvasPixelSize: canvasPixelSize,
            isCanvasInteracting: isCanvasInteracting
        )
        guard let adapted = semanticAttempt.adaptedSegments, !adapted.isEmpty else {
            return nil
        }
        return adapted
    }

    private static func viewportSamplingRanges(
        canvasState: CanvasState
    ) -> (xRange: SamplingRange, yRange: SamplingRange) {
        let pointsPerUnit = max(0.000001, canvasState.scale)
        let halfW = 512.0 / pointsPerUnit
        let centerX = -Double(canvasState.origin.x) / pointsPerUnit
        let halfH = 320.0 / pointsPerUnit
        let centerY = Double(canvasState.origin.y) / pointsPerUnit
        let xRange = SamplingRange(lower: centerX - halfW, upper: centerX + halfW)
        let yRange = SamplingRange(lower: centerY - halfH, upper: centerY + halfH)
        return (xRange, yRange)
    }

    private static func samplingViewport2D(
        from ranges: (xRange: SamplingRange, yRange: SamplingRange),
        canvasPixelSize: CGSize?
    ) -> SamplingViewport2D {
        PlaneSamplingViewportResolver.makeViewport(
            xRange: ranges.xRange,
            yRange: ranges.yRange,
            canvasPixelSize: canvasPixelSize
        )
    }

    private static func semanticSamplingQualityProfile(
        formulaInputState: FormulaInputState,
        isCanvasInteracting: Bool
    ) -> SamplingQualityProfile {
        let policy = PlaneSamplingQualityPolicy()
        return policy.qualityProfile(
            isInputEditing: formulaInputState.isEditing,
            isCanvasInteracting: isCanvasInteracting,
            userPreferred: .balanced
        )
    }

    #if DEBUG
    private static func runSemanticSamplingDebugIfNeeded(
        formulaInputState: FormulaInputState,
        document: EMathicaDocument,
        canvasState: CanvasState,
        canvasPixelSize: CGSize?,
        isCanvasInteracting: Bool
    ) {
        guard semanticSamplingDebugEnabled else { return }

        let semanticState = formulaInputState.semanticState
        if semanticState.hasBlockingError {
            print("[PlanePreview][SemanticSamplingDebug] blocked: \(semanticState.debugSummary)")
            return
        }
        guard let graphClassification = semanticState.graphClassification else {
            print("[PlanePreview][SemanticSamplingDebug] skipped: graphClassification=nil")
            return
        }

        let ranges = viewportSamplingRanges(canvasState: canvasState)
        let qualityProfile = semanticSamplingQualityProfile(
            formulaInputState: formulaInputState,
            isCanvasInteracting: isCanvasInteracting
        )
        let viewport = samplingViewport2D(from: ranges, canvasPixelSize: canvasPixelSize)
        let sampleSet = PlaneFallbackSamplingService.sampler(qualityProfile: qualityProfile).sample(
            intent: graphClassification.intent,
            xRange: ranges.xRange,
            yRange: ranges.yRange,
            viewport: viewport,
            environment: currentParameterEnvironment(from: document)
        )
        let intentSummary = GraphIntentDebugPrinter().print(graphClassification.intent)
        let summary = PlaneSemanticSamplingDebugFormatter.makeResult(
            intentSummary: intentSummary,
            sampleSet: sampleSet
        )
        print("[PlanePreview][SemanticSamplingDebug] intent=\(summary.intentSummary) segments=\(summary.segmentCount) points=\(summary.pointCount) issues=\(summary.issueCount) issueSummary=\(summary.issueSummary)")
    }

    private static func makeSemanticPreviewSegmentsIfAvailable(
        formulaInputState: FormulaInputState,
        document: EMathicaDocument,
        canvasState: CanvasState,
        canvasPixelSize: CGSize?,
        isCanvasInteracting: Bool
    ) -> [PlotSegment]? {
        let semanticAttempt = makeSemanticSamplingAttempt(
            formulaInputState: formulaInputState,
            document: document,
            canvasState: canvasState,
            enforceDefaultPolicy: false,
            canvasPixelSize: canvasPixelSize,
            isCanvasInteracting: isCanvasInteracting
        )
        guard let adapted = semanticAttempt.adaptedSegments, !adapted.isEmpty else {
            if let reason = semanticAttempt.fallbackReason {
                print("[PlanePreview][SemanticSamplingPreview] fallback: \(reason.rawValue)")
            } else {
                print("[PlanePreview][SemanticSamplingPreview] fallback: adapter nil/empty")
            }
            return nil
        }
        return adapted
    }

    private static func runSemanticSamplingComparisonIfNeeded(
        formulaInputState: FormulaInputState,
        document: EMathicaDocument,
        canvasState: CanvasState,
        legacySegments: [PlotSegment],
        canvasPixelSize: CGSize?,
        isCanvasInteracting: Bool
    ) {
        let semanticAttempt = makeSemanticSamplingAttempt(
            formulaInputState: formulaInputState,
            document: document,
            canvasState: canvasState,
            enforceDefaultPolicy: false,
            canvasPixelSize: canvasPixelSize,
            isCanvasInteracting: isCanvasInteracting
        )
        let comparison = PlaneSamplingComparisonDebugFormatter.makeResult(
            inputSummary: formulaInputState.computeExpression,
            intentSummary: semanticAttempt.intentSummary,
            legacySegments: legacySegments,
            semanticSampleSet: semanticAttempt.sampleSet,
            adaptedSemanticSegments: semanticAttempt.adaptedSegments,
            fallbackReason: semanticAttempt.fallbackReason
        )
        print("[PlanePreview][SamplingCompare] input=\(comparison.inputSummary) intent=\(comparison.intentSummary) legacySegments=\(comparison.legacySegmentCount) legacyPoints=\(comparison.legacyPointCount) semanticSegments=\(comparison.semanticSegmentCount) semanticPoints=\(comparison.semanticPointCount) semanticIssues=\(comparison.semanticIssueCount) semanticIssueSummary=\(comparison.semanticIssueSummary) fallbackReason=\(comparison.fallbackReason ?? "none")")
    }

    private static func makeSemanticSamplingAttempt(
        formulaInputState: FormulaInputState,
        document: EMathicaDocument,
        canvasState: CanvasState,
        enforceDefaultPolicy: Bool,
        canvasPixelSize: CGSize?,
        isCanvasInteracting: Bool
    ) -> (
        sampleSet: SampleSet2D?,
        adaptedSegments: [PlotSegment]?,
        intentSummary: String,
        fallbackReason: PlaneSemanticFallbackReason?,
        diagnostics: [FormulaPlotDiagnostic]
    ) {
        let semanticState = formulaInputState.semanticState
        var diagnostics = semanticState.plotDiagnostics(source: .draft)
        let parameterSymbolNames = Set(currentParameterValues(from: document).keys)
        if semanticState.expression == nil,
           semanticState.diagnostics.isEmpty,
           semanticState.graphClassification == nil {
            diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .serialization,
                    severity: .error,
                    code: "missing_semantic_state",
                    message: "语义状态为空，无法进行预览采样",
                    source: .draft
                )
            )
            return (nil, nil, "nil", .noSemanticState, diagnostics)
        }
        if semanticState.hasBlockingError {
            return (nil, nil, "nil", .semanticBlockingError, diagnostics)
        }
        let resolveResult = PlaneFallbackSamplingService.resolveIntentWithDiagnostics(
            expression: semanticState.expression,
            classification: semanticState.graphClassification,
            parameterSymbolNames: parameterSymbolNames,
            source: .draft
        )
        diagnostics.append(contentsOf: resolveResult.diagnostics)
        guard let resolved = resolveResult.resolved else {
            return (nil, nil, "nil", semanticState.graphClassification == nil ? .missingGraphClassification : .unsupportedGraphIntent, diagnostics)
        }

        let intent = resolved.intent
        let intentSummary = GraphIntentDebugPrinter().print(intent)
        if enforceDefaultPolicy {
            let policy = PlaneSemanticPreviewPolicy()
            let shouldUsePolicy = policy.shouldUseSemanticPreview(for: intent)
            guard shouldUsePolicy || resolved.source == .fallback else {
                diagnostics.append(
                    FormulaPlotDiagnostic(
                        stage: .classification,
                        severity: .warning,
                        code: "semantic_policy_rejected_intent",
                        message: "当前语义策略未启用该意图的预览采样",
                        source: .draft
                    )
                )
                return (nil, nil, intentSummary, .unsupportedGraphIntent, diagnostics)
            }
        }

        let ranges = viewportSamplingRanges(canvasState: canvasState)
        let qualityProfile = semanticSamplingQualityProfile(
            formulaInputState: formulaInputState,
            isCanvasInteracting: isCanvasInteracting
        )
        let viewport = samplingViewport2D(from: ranges, canvasPixelSize: canvasPixelSize)
        var sampleSet = PlaneFallbackSamplingService.sampler(qualityProfile: qualityProfile).sample(
            intent: intent,
            xRange: ranges.xRange,
            yRange: ranges.yRange,
            viewport: viewport,
            environment: currentParameterEnvironment(from: document)
        )
        sampleSet = PlaneFallbackSamplingService.limitSegmentsIfNeeded(sampleSet, intent: intent)
        diagnostics.append(contentsOf: PlaneFallbackSamplingService.diagnosticsForSampleSet(sampleSet, intent: intent, source: .draft))
        if sampleSet.segments.isEmpty {
            return (sampleSet, nil, intentSummary, .emptySemanticSampleSet, diagnostics)
        }
        guard let adapted = PlaneSampleSetAdapter.adaptToPlotSegments(sampleSet) else {
            diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .rendering,
                    severity: .error,
                    code: "plot_segment_adapter_failed",
                    message: "采样结果无法转换为绘制片段",
                    source: .draft
                )
            )
            return (sampleSet, nil, intentSummary, .adapterFailed, diagnostics)
        }
        return (sampleSet, adapted, intentSummary, nil, diagnostics)
    }

    #endif
}
