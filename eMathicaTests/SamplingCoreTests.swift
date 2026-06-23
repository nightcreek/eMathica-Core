import Testing
import Foundation
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct SamplingCoreTests {
    @Test func sampleYLinearSingleSegment() throws {
        let sampler = ExplicitFunctionSampler2D(
            options: .init(
                qualityProfile: .preview,
                algorithm: .uniform,
                initialSampleCount: 64,
                maxSampleCount: 64,
                maxRefinementDepth: 0,
                discontinuityThreshold: 1000,
                maxAbsCoordinate: 1.0e12,
                refinementErrorThreshold: .infinity,
                screenErrorTolerance: nil
            )
        )
        let set = sampler.sampleY(
            expression: .symbol(Symbol(name: "x", role: .variable)),
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.segments.count == 1)
    }

    @Test func sampleYQuadraticSingleSegment() throws {
        let expr = Expr.power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D().sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.segments.count == 1)
    }

    @Test func sampleYSinPeakNearOne() throws {
        let expr = Expr.function(.sin, arguments: [.symbol(Symbol(name: "x", role: .variable))])
        let set = ExplicitFunctionSampler2D().sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: 0, upper: Double.pi)
        )
        let maxY = set.segments.flatMap(\.points).map(\.y).max() ?? -1
        #expect(maxY > 0.99)
    }

    @Test func sampleYOneOverXBreaksAroundZero() throws {
        let expr = Expr.divide(
            numerator: .integer(1),
            denominator: .add([
                .symbol(Symbol(name: "x", role: .variable)),
                .negate(.symbol(Symbol(name: "x", role: .variable)))
            ])
        )
        let set = ExplicitFunctionSampler2D().sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
        #expect(set.segments.isEmpty)
    }

    @Test func sampleYSqrtNegativeSideUndefined() throws {
        let expr = Expr.function(.sqrt, arguments: [.symbol(Symbol(name: "x", role: .variable))])
        let set = ExplicitFunctionSampler2D().sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
        #expect(set.segments.flatMap(\.points).contains { $0.x >= 0 })
    }

    @Test func sampleYLnNegativeSideUndefined() throws {
        let expr = Expr.function(.ln, arguments: [.symbol(Symbol(name: "x", role: .variable))])
        let set = ExplicitFunctionSampler2D().sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func invalidRangeIssue() throws {
        let set = ExplicitFunctionSampler2D().sampleY(
            expression: .symbol(Symbol(name: "x", role: .variable)),
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: 1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .invalidRange })
    }

    @Test func insufficientSamplesIssue() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 1,
            maxSampleCount: 1,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: .symbol(Symbol(name: "x", role: .variable)),
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .insufficientSamples })
    }

    @Test func maxAbsCoordinateTriggersNonFinitePointIssue() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 16,
            maxSampleCount: 16,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 10,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let expr = Expr.multiply([.integer(100), .symbol(Symbol(name: "x", role: .variable))])
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .nonFinitePoint })
    }

    @Test func discontinuityThresholdTriggersIssue() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 8,
            maxSampleCount: 8,
            maxRefinementDepth: 0,
            discontinuityThreshold: 0.5,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let expr = Expr.multiply([.integer(10), .symbol(Symbol(name: "x", role: .variable))])
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .possibleDiscontinuity })
    }

    @Test func qualityProfileIncludesFourCases() throws {
        #expect(SamplingQualityProfile.allCases.count == 4)
    }

    @Test func profileResolverReturnsOptionsForAllProfiles() throws {
        let resolver = SamplingProfileResolver()
        for profile in SamplingQualityProfile.allCases {
            let options = resolver.curveOptions2D(for: profile)
            #expect(options.qualityProfile == profile)
        }
    }

    @Test func previewSamplesLessThanBalanced() throws {
        let preview = CurveSamplingOptions2D.defaults(for: .preview)
        let balanced = CurveSamplingOptions2D.defaults(for: .balanced)
        #expect(preview.initialSampleCount < balanced.initialSampleCount)
    }

    @Test func preciseMaxSamplesGreaterThanBalanced() throws {
        let precise = CurveSamplingOptions2D.defaults(for: .precise)
        let balanced = CurveSamplingOptions2D.defaults(for: .balanced)
        #expect(precise.maxSampleCount > balanced.maxSampleCount)
    }

    @Test func namingAndBoundaryCompilationChecks() throws {
        let _: SamplePoint2D = .init(x: 0, y: 0)
        let _: SampleSet2D = .init(segments: [], issues: [])
        let _: ExplicitFunctionSampler2D = .init()
        let _: GraphIntentSampler2D = .init()
        #expect(Bool(true))
    }

    @Test func graphIntentSamplerQualityProfileInitDowngradesImplicitResolutionForPreview() throws {
        let preview = GraphIntentSampler2D(qualityProfile: .preview)
        let balanced = GraphIntentSampler2D(qualityProfile: .balanced)
        #expect(preview.implicitCurveSampler.options.xResolution < balanced.implicitCurveSampler.options.xResolution)
        #expect(preview.implicitCurveSampler.options.yResolution < balanced.implicitCurveSampler.options.yResolution)
    }

    @Test func graphIntentSamplerQualityProfileBalancedCanSampleImplicit() throws {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let set = GraphIntentSampler2D(qualityProfile: .balanced).sample(
            intent: .implicit(relation: relation),
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func sampleXQuadraticSingleSegment() throws {
        let expr = Expr.power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D().sampleX(
            expression: expr,
            variable: Symbol(name: "y", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.segments.count == 1)
    }

    @Test func sampleXUsesSampledVariableAsYAndEvaluatedAsX() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 3,
            maxSampleCount: 3,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let expr = Expr.power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D(options: options).sampleX(
            expression: expr,
            variable: Symbol(name: "y", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        let points = set.segments.flatMap(\.points)
        #expect(points.count == 3)
        let middle = points[1]
        #expect(abs(middle.y - 0) < 1e-12)
        #expect(abs(middle.x - 0) < 1e-12)
        let first = points[0]
        #expect(abs(first.y - (-1)) < 1e-12)
        #expect(abs(first.x - 1) < 1e-12)
    }

    @Test func sampleXDivideByZeroBreaksAndReportsUndefined() throws {
        let expr = Expr.divide(
            numerator: .integer(1),
            denominator: .add([
                .symbol(Symbol(name: "y", role: .variable)),
                .negate(.symbol(Symbol(name: "y", role: .variable)))
            ])
        )
        let set = ExplicitFunctionSampler2D().sampleX(
            expression: expr,
            variable: Symbol(name: "y", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func sampleXDiscontinuityThresholdTriggersIssue() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 8,
            maxSampleCount: 8,
            maxRefinementDepth: 0,
            discontinuityThreshold: 0.5,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let expr = Expr.multiply([.integer(10), .symbol(Symbol(name: "y", role: .variable))])
        let set = ExplicitFunctionSampler2D(options: options).sampleX(
            expression: expr,
            variable: Symbol(name: "y", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .possibleDiscontinuity })
    }

    @Test func graphIntentSamplerSupportsExplicitY() throws {
        let intent = GraphIntent.explicitY(
            expression: .symbol(Symbol(name: "x", role: .variable)),
            variable: Symbol(name: "x", role: .variable)
        )
        let viewport = SamplingViewport2D(
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1),
            pixelWidth: 600,
            pixelHeight: 600
        )
        let set = GraphIntentSampler2D().sample(
            intent: intent,
            xRange: .init(lower: -1, upper: 1),
            viewport: viewport
        )
        #expect(!set.segments.isEmpty)
        #expect(!set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func graphIntentSamplerSupportsExplicitX() throws {
        let intent = GraphIntent.explicitX(
            expression: .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2)),
            variable: Symbol(name: "y", role: .variable)
        )
        let set = GraphIntentSampler2D().sample(
            intent: intent,
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1)
        )
        #expect(!set.segments.isEmpty)
        #expect(!set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func graphIntentSamplerImplicitWithoutYRangeReturnsInvalidRange() throws {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let set = GraphIntentSampler2D().sample(
            intent: .implicit(relation: relation),
            xRange: .init(lower: -1, upper: 1)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .invalidRange })
    }

    @Test func graphIntentSamplerParametricReturnsSampleSet() throws {
        let set = GraphIntentSampler2D().sample(
            intent: .parametric2D(
                x: .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
                y: .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
                parameter: Symbol(name: "t", role: .parameter),
                range: nil
            ),
            xRange: .init(lower: -1, upper: 1)
        )
        #expect(!set.segments.isEmpty)
        #expect(!set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func graphIntentSamplerUnknownReturnsUnsupportedIntent() throws {
        let set = GraphIntentSampler2D().sample(
            intent: .unknown(.unknown("todo")),
            xRange: .init(lower: -1, upper: 1)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func previewUniformDoesNotRefine() throws {
        let options = CurveSamplingOptions2D.defaults(for: .preview)
        let expr = Expr.power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count == options.initialSampleCount)
    }

    @Test func balancedRefinesAndAddsPointsForQuadratic() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .balanced,
            algorithm: .uniformWithBasicRefinement,
            initialSampleCount: 5,
            maxSampleCount: 50,
            maxRefinementDepth: 3,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 2.0
        )
        let expr = Expr.power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count > options.initialSampleCount)
    }

    @Test func balancedLinearDoesNotOverRefine() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .balanced,
            algorithm: .uniformWithBasicRefinement,
            initialSampleCount: 5,
            maxSampleCount: 50,
            maxRefinementDepth: 3,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 2.0
        )
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: .symbol(Symbol(name: "x", role: .variable)),
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count == options.initialSampleCount)
    }

    @Test func refinementDepthLimitIsRespected() throws {
        let expr = Expr.power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2))
        let depth0 = CurveSamplingOptions2D(
            qualityProfile: .balanced,
            algorithm: .uniformWithBasicRefinement,
            initialSampleCount: 5,
            maxSampleCount: 100,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.0001,
            screenErrorTolerance: 2.0
        )
        let depth3 = CurveSamplingOptions2D(
            qualityProfile: .balanced,
            algorithm: .uniformWithBasicRefinement,
            initialSampleCount: 5,
            maxSampleCount: 100,
            maxRefinementDepth: 3,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.0001,
            screenErrorTolerance: 2.0
        )
        let count0 = ExplicitFunctionSampler2D(options: depth0).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        ).segments.flatMap(\.points).count
        let count3 = ExplicitFunctionSampler2D(options: depth3).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        ).segments.flatMap(\.points).count
        #expect(count3 >= count0)
    }

    @Test func maxSampleCountLimitIsRespected() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .balanced,
            algorithm: .uniformWithBasicRefinement,
            initialSampleCount: 5,
            maxSampleCount: 7,
            maxRefinementDepth: 8,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.00001,
            screenErrorTolerance: 2.0
        )
        let expr = Expr.power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count <= options.maxSampleCount)
    }

    @Test func sampleXSupportsRefinement() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .balanced,
            algorithm: .uniformWithBasicRefinement,
            initialSampleCount: 5,
            maxSampleCount: 50,
            maxRefinementDepth: 3,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 2.0
        )
        let expr = Expr.power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D(options: options).sampleX(
            expression: expr,
            variable: Symbol(name: "y", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count > options.initialSampleCount)
    }

    @Test func sampleXAdaptiveScreenSpaceWorks() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .precise,
            algorithm: .adaptiveScreenSpace,
            initialSampleCount: 5,
            maxSampleCount: 128,
            maxRefinementDepth: 6,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 0.5
        )
        let viewport = SamplingViewport2D(
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1),
            pixelWidth: 600,
            pixelHeight: 600
        )
        let expr = Expr.power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D(options: options).sampleX(
            expression: expr,
            variable: Symbol(name: "y", role: .variable),
            range: .init(lower: -1, upper: 1),
            viewport: viewport
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count > options.initialSampleCount)
    }

    @Test func adaptiveScreenSpaceFallsBackToBasicRefinement() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .precise,
            algorithm: .adaptiveScreenSpace,
            initialSampleCount: 5,
            maxSampleCount: 50,
            maxRefinementDepth: 3,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 0.75
        )
        let expr = Expr.power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func hybridExploratoryFallsBackToBasicRefinement() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .exploratory,
            algorithm: .hybridExploratory,
            initialSampleCount: 5,
            maxSampleCount: 50,
            maxRefinementDepth: 3,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 0.5
        )
        let expr = Expr.power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2))
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func samplingViewportProjectionMapsIntoPixelSpace() throws {
        let viewport = SamplingViewport2D(
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1),
            pixelWidth: 200,
            pixelHeight: 100
        )
        let projectedCenter = viewport.project(.init(x: 0, y: 0))
        #expect(abs(projectedCenter.x - 100) < 1e-9)
        #expect(abs(projectedCenter.y - 50) < 1e-9)
        let projectedTopRight = viewport.project(.init(x: 1, y: 1))
        #expect(abs(projectedTopRight.x - 200) < 1e-9)
        #expect(abs(projectedTopRight.y - 0) < 1e-9)
    }

    @Test func adaptiveScreenSpaceLinearDoesNotOverRefine() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .precise,
            algorithm: .adaptiveScreenSpace,
            initialSampleCount: 5,
            maxSampleCount: 64,
            maxRefinementDepth: 6,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.0001,
            screenErrorTolerance: 1.0
        )
        let viewport = SamplingViewport2D(
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1),
            pixelWidth: 600,
            pixelHeight: 600
        )
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: .symbol(Symbol(name: "x", role: .variable)),
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1),
            viewport: viewport
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count == options.initialSampleCount)
    }

    @Test func adaptiveScreenSpaceQuadraticAddsPoints() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .precise,
            algorithm: .adaptiveScreenSpace,
            initialSampleCount: 5,
            maxSampleCount: 128,
            maxRefinementDepth: 6,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.0001,
            screenErrorTolerance: 0.5
        )
        let viewport = SamplingViewport2D(
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1),
            pixelWidth: 600,
            pixelHeight: 600
        )
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1),
            viewport: viewport
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count > options.initialSampleCount)
        #expect(count <= options.maxSampleCount)
    }

    @Test func adaptiveScreenSpaceWithoutViewportFallsBackToBasicRefinement() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .precise,
            algorithm: .adaptiveScreenSpace,
            initialSampleCount: 5,
            maxSampleCount: 128,
            maxRefinementDepth: 6,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 0.5
        )
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count > options.initialSampleCount)
    }

    @Test func refinementDoesNotBridgeDivisionByZero() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .balanced,
            algorithm: .uniformWithBasicRefinement,
            initialSampleCount: 5,
            maxSampleCount: 50,
            maxRefinementDepth: 4,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 2.0
        )
        let expr = Expr.divide(numerator: .integer(1), denominator: .symbol(Symbol(name: "x", role: .variable)))
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
        #expect(set.segments.count >= 2)
    }

    @Test func refinementStillRespectsDiscontinuityBreak() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .balanced,
            algorithm: .uniformWithBasicRefinement,
            initialSampleCount: 5,
            maxSampleCount: 50,
            maxRefinementDepth: 4,
            discontinuityThreshold: 0.5,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 2.0
        )
        let expr = Expr.multiply([.integer(10), .symbol(Symbol(name: "x", role: .variable))])
        let set = ExplicitFunctionSampler2D(options: options).sampleY(
            expression: expr,
            variable: Symbol(name: "x", role: .variable),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .possibleDiscontinuity })
    }

    @Test func parametricCircleSamplingProducesSegments() throws {
        let sampler = ParametricCurveSampler2D()
        let set = sampler.sample(
            xExpression: .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
            yExpression: .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: 0, upper: 2 * Double.pi)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func parametricCirclePointsSatisfyUnitCircleApproximately() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 32,
            maxSampleCount: 32,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let set = ParametricCurveSampler2D(options: options).sample(
            xExpression: .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
            yExpression: .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: 0, upper: 2 * Double.pi)
        )
        let points = set.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        let maxError = points.map { abs(($0.x * $0.x + $0.y * $0.y) - 1) }.max() ?? 1
        #expect(maxError < 1e-6)
    }

    @Test func parametricUndefinedXBreaksAndReportsIssue() throws {
        let set = ParametricCurveSampler2D().sample(
            xExpression: .divide(
                numerator: .integer(1),
                denominator: .add([
                    .symbol(Symbol(name: "t", role: .parameter)),
                    .negate(.symbol(Symbol(name: "t", role: .parameter)))
                ])
            ),
            yExpression: .symbol(Symbol(name: "t", role: .parameter)),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func parametricUndefinedYBreaksAndReportsIssue() throws {
        let set = ParametricCurveSampler2D().sample(
            xExpression: .symbol(Symbol(name: "t", role: .parameter)),
            yExpression: .function(.sqrt, arguments: [.negate(.integer(1))]),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func parametricNonFiniteTriggersIssue() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 8,
            maxSampleCount: 8,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let set = ParametricCurveSampler2D(options: options).sample(
            xExpression: .multiply([.integer(10), .symbol(Symbol(name: "t", role: .parameter))]),
            yExpression: .symbol(Symbol(name: "t", role: .parameter)),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .nonFinitePoint })
    }

    @Test func parametricJumpTriggersDiscontinuityIssue() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 8,
            maxSampleCount: 8,
            maxRefinementDepth: 0,
            discontinuityThreshold: 0.5,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let set = ParametricCurveSampler2D(options: options).sample(
            xExpression: .multiply([.integer(10), .symbol(Symbol(name: "t", role: .parameter))]),
            yExpression: .symbol(Symbol(name: "t", role: .parameter)),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .possibleDiscontinuity })
    }

    @Test func parametricRefinementAddsPointsForCurvedPath() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .balanced,
            algorithm: .uniformWithBasicRefinement,
            initialSampleCount: 5,
            maxSampleCount: 64,
            maxRefinementDepth: 4,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 2.0
        )
        let set = ParametricCurveSampler2D(options: options).sample(
            xExpression: .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
            yExpression: .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: 0, upper: 2 * Double.pi)
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count > options.initialSampleCount)
    }

    @Test func parametricAdaptiveScreenSpaceAddsPointsForCurvedPath() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .precise,
            algorithm: .adaptiveScreenSpace,
            initialSampleCount: 5,
            maxSampleCount: 128,
            maxRefinementDepth: 6,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: 0.01,
            screenErrorTolerance: 0.5
        )
        let viewport = SamplingViewport2D(
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1),
            pixelWidth: 600,
            pixelHeight: 600
        )
        let set = ParametricCurveSampler2D(options: options).sample(
            xExpression: .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
            yExpression: .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: 0, upper: 2 * Double.pi),
            viewport: viewport
        )
        let count = set.segments.flatMap(\.points).count
        #expect(count > options.initialSampleCount)
        #expect(count <= options.maxSampleCount)
    }

    @Test func polarSamplerSupportsViewportPath() throws {
        let viewport = SamplingViewport2D(
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2),
            pixelWidth: 600,
            pixelHeight: 600
        )
        let set = PolarCurveSampler2D().sample(
            radiusExpression: .integer(1),
            angle: Symbol(name: "t", role: .parameter),
            range: .init(lower: 0, upper: 2 * Double.pi),
            viewport: viewport
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func circleSamplerSupportsViewportPath() throws {
        let viewport = SamplingViewport2D(
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2),
            pixelWidth: 600,
            pixelHeight: 600
        )
        let set = PrimitiveSampler2D().sampleCircle(
            center: .tuple([.integer(0), .integer(0)]),
            radius: .integer(1),
            viewport: viewport
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func parametricInvalidRangeIssue() throws {
        let set = ParametricCurveSampler2D().sample(
            xExpression: .symbol(Symbol(name: "t", role: .parameter)),
            yExpression: .symbol(Symbol(name: "t", role: .parameter)),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: 1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .invalidRange })
    }

    @Test func parametricInsufficientSamplesIssue() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 1,
            maxSampleCount: 1,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let set = ParametricCurveSampler2D(options: options).sample(
            xExpression: .symbol(Symbol(name: "t", role: .parameter)),
            yExpression: .symbol(Symbol(name: "t", role: .parameter)),
            parameter: Symbol(name: "t", role: .parameter),
            range: .init(lower: 0, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .insufficientSamples })
    }

    @Test func graphIntentSamplerParametricNilRangeFallsBackToZeroToTwoPi() throws {
        let set = GraphIntentSampler2D().sample(
            intent: .parametric2D(
                x: .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
                y: .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
                parameter: Symbol(name: "t", role: .parameter),
                range: nil
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func graphIntentSamplerParametricInvalidRangeFallsBackToZeroToTwoPi() throws {
        let set = GraphIntentSampler2D().sample(
            intent: .parametric2D(
                x: .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
                y: .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
                parameter: Symbol(name: "t", role: .parameter),
                range: .init(lower: .symbol(Symbol(name: "bad", role: .variable)), upper: .integer(1))
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func graphIntentSamplerParametricUsesProvidedRangeInsteadOfFallback() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 3,
            maxSampleCount: 3,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let sampler = GraphIntentSampler2D(
            parametricCurveSampler: .init(options: options)
        )
        let set = sampler.sample(
            intent: .parametric2D(
                x: .symbol(Symbol(name: "t", role: .parameter)),
                y: .power(base: .symbol(Symbol(name: "t", role: .parameter)), exponent: .integer(2)),
                parameter: Symbol(name: "t", role: .parameter),
                range: .init(lower: .integer(0), upper: .integer(2))
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        let points = set.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        let last = points.last
        #expect(abs((last?.x ?? 0) - 2) < 1e-9)
        #expect(abs((last?.y ?? 0) - 4) < 1e-9)
    }

    @Test func graphIntentSamplerParametricRangeZeroToOneEndsNearOneOne() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 5,
            maxSampleCount: 5,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let sampler = GraphIntentSampler2D(
            parametricCurveSampler: .init(options: options)
        )
        let set = sampler.sample(
            intent: .parametric2D(
                x: .symbol(Symbol(name: "t", role: .parameter)),
                y: .power(base: .symbol(Symbol(name: "t", role: .parameter)), exponent: .integer(2)),
                parameter: Symbol(name: "t", role: .parameter),
                range: .init(lower: .integer(0), upper: .integer(1))
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        let points = set.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        let last = points.last
        #expect(abs((last?.x ?? 0) - 1) < 1e-9)
        #expect(abs((last?.y ?? 0) - 1) < 1e-9)
    }

    @Test func graphIntentSamplerParametricConstantYRespectsProvidedRangeBounds() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 6,
            maxSampleCount: 6,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let sampler = GraphIntentSampler2D(
            parametricCurveSampler: .init(options: options)
        )
        let set = sampler.sample(
            intent: .parametric2D(
                x: .symbol(Symbol(name: "t", role: .parameter)),
                y: .integer(1),
                parameter: Symbol(name: "t", role: .parameter),
                range: .init(lower: .integer(0), upper: .integer(1))
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        let points = set.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        let minX = points.map(\.x).min() ?? .infinity
        let maxX = points.map(\.x).max() ?? -.infinity
        #expect(minX >= -1e-9)
        #expect(maxX <= 1 + 1e-9)
        #expect(points.allSatisfy { abs($0.y - 1) <= 1e-9 })
    }

    @Test func graphIntentSamplerUsesPiUpperBoundFromParsedRangeNotFallback() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 5,
            maxSampleCount: 5,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let sampler = GraphIntentSampler2D(
            parametricCurveSampler: .init(options: options)
        )
        let set = sampler.sample(
            intent: .parametric2D(
                x: .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
                y: .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .parameter))]),
                parameter: Symbol(name: "t", role: .parameter),
                range: .init(lower: .integer(0), upper: .constant(.pi))
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        let points = set.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        // If fallback 0...2π were used, the last point would be close to (0, 1), not (0, -1).
        let last = points.last
        #expect(abs(last?.x ?? 1) < 1e-6)
        #expect(abs((last?.y ?? 0) + 1) < 1e-6)
    }

    @Test func polarUnitCircleProducesSegments() throws {
        let sampler = PolarCurveSampler2D()
        let set = sampler.sample(
            radiusExpression: .integer(1),
            angle: Symbol(name: "theta", role: .parameter),
            range: .init(lower: 0, upper: 2 * Double.pi)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func polarUnitCirclePointsSatisfyCircleApproximately() throws {
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 32,
            maxSampleCount: 32,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let set = PolarCurveSampler2D(
            parametricCurveSampler: .init(options: options)
        ).sample(
            radiusExpression: .integer(1),
            angle: Symbol(name: "theta", role: .parameter),
            range: .init(lower: 0, upper: 2 * Double.pi)
        )
        let points = set.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        let maxError = points.map { abs(($0.x * $0.x + $0.y * $0.y) - 1) }.max() ?? 1
        #expect(maxError < 1e-6)
    }

    @Test func polarSinThetaProducesSampleSet() throws {
        let set = PolarCurveSampler2D().sample(
            radiusExpression: .function(.sin, arguments: [.symbol(Symbol(name: "theta", role: .parameter))]),
            angle: Symbol(name: "theta", role: .parameter),
            range: .init(lower: 0, upper: 2 * Double.pi)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func polarUndefinedRadiusReportsEvaluationUndefined() throws {
        let set = PolarCurveSampler2D().sample(
            radiusExpression: .divide(numerator: .integer(1), denominator: .integer(0)),
            angle: Symbol(name: "theta", role: .parameter),
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func graphIntentSamplerSupportsPolar() throws {
        let set = GraphIntentSampler2D().sample(
            intent: .polar(
                radius: .integer(1),
                angle: Symbol(name: "theta", role: .parameter),
                range: .init(lower: .integer(0), upper: .multiply([.integer(2), .constant(.pi)]))
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        #expect(!set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func graphIntentSamplerPolarNilRangeFallsBackToZeroToTwoPi() throws {
        let set = GraphIntentSampler2D().sample(
            intent: .polar(
                radius: .integer(1),
                angle: Symbol(name: "theta", role: .parameter),
                range: nil
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func graphIntentSamplerPolarInvalidRangeFallsBackToZeroToTwoPi() throws {
        let set = GraphIntentSampler2D().sample(
            intent: .polar(
                radius: .integer(1),
                angle: Symbol(name: "theta", role: .parameter),
                range: .init(lower: .symbol(Symbol(name: "bad", role: .variable)), upper: .integer(1))
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func primitiveSamplerPointReturnsOnePointSegment() throws {
        let set = PrimitiveSampler2D().samplePoint(x: .integer(1), y: .integer(2))
        #expect(set.issues.isEmpty)
        #expect(set.segments.count == 1)
        #expect(set.segments[0].points.count == 1)
        #expect(abs(set.segments[0].points[0].x - 1) < 1e-12)
        #expect(abs(set.segments[0].points[0].y - 2) < 1e-12)
    }

    @Test func primitiveSamplerPointUndefinedXReportsEvaluationUndefined() throws {
        let set = PrimitiveSampler2D().samplePoint(
            x: .divide(numerator: .integer(1), denominator: .integer(0)),
            y: .integer(2)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func primitiveSamplerPointUndefinedYReportsEvaluationUndefined() throws {
        let set = PrimitiveSampler2D().samplePoint(
            x: .integer(2),
            y: .function(.sqrt, arguments: [.integer(-1)])
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func primitiveSamplerPointNonFiniteReportsIssue() throws {
        let set = PrimitiveSampler2D().samplePoint(
            x: .real(.nan),
            y: .integer(2)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .nonFinitePoint })
    }

    @Test func primitiveSamplerCircleUnitCircleProducesSamples() throws {
        let set = PrimitiveSampler2D().sampleCircle(
            center: .tuple([.integer(0), .integer(0)]),
            radius: .integer(1)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let maxError = points.map { abs(($0.x * $0.x + $0.y * $0.y) - 1) }.max() ?? 1
        #expect(maxError < 1e-4)
    }

    @Test func primitiveSamplerCircleNonTupleCenterUnsupported() throws {
        let set = PrimitiveSampler2D().sampleCircle(
            center: .vector([.integer(0), .integer(0)]),
            radius: .integer(1)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func primitiveSamplerCircleNonPositiveRadiusUnsupported() throws {
        let set = PrimitiveSampler2D().sampleCircle(
            center: .tuple([.integer(0), .integer(0)]),
            radius: .integer(0)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func primitiveSamplerCircleUndefinedRadiusReportsEvaluationUndefined() throws {
        let set = PrimitiveSampler2D().sampleCircle(
            center: .tuple([.integer(0), .integer(0)]),
            radius: .function(.sqrt, arguments: [.integer(-1)])
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func graphIntentSamplerSupportsPointIntent() throws {
        let set = GraphIntentSampler2D().sample(
            intent: .point(x: .integer(1), y: .integer(2)),
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(set.issues.isEmpty)
        #expect(set.segments.count == 1)
        #expect(set.segments[0].points.count == 1)
    }

    @Test func graphIntentSamplerSupportsCircleIntent() throws {
        let set = GraphIntentSampler2D().sample(
            intent: .circle(
                center: .tuple([.integer(0), .integer(0)]),
                radius: .integer(1)
            ),
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        #expect(!set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func segmentStitcherConcatenatesTailToHead() throws {
        let stitcher = SegmentStitcher2D(tolerance: 1e-9)
        let stitched = stitcher.stitch([
            .init(points: [.init(x: 0, y: 0), .init(x: 1, y: 0)]),
            .init(points: [.init(x: 1, y: 0), .init(x: 2, y: 0)])
        ])
        #expect(stitched.count == 1)
        #expect(stitched[0].points.count == 3)
    }

    @Test func segmentStitcherSupportsReverseConnection() throws {
        let stitcher = SegmentStitcher2D(tolerance: 1e-9)
        let stitched = stitcher.stitch([
            .init(points: [.init(x: 0, y: 0), .init(x: 1, y: 0)]),
            .init(points: [.init(x: 2, y: 0), .init(x: 1, y: 0)])
        ])
        #expect(stitched.count == 1)
        #expect(stitched[0].points.count == 3)
        #expect(abs((stitched[0].points.first?.x ?? 99) - 0) < 1e-9)
        #expect(abs((stitched[0].points.last?.x ?? -99) - 2) < 1e-9)
    }

    @Test func segmentStitcherKeepsDisconnectedSegmentsSeparate() throws {
        let stitcher = SegmentStitcher2D(tolerance: 1e-9)
        let stitched = stitcher.stitch([
            .init(points: [.init(x: 0, y: 0), .init(x: 1, y: 0)]),
            .init(points: [.init(x: 3, y: 0), .init(x: 4, y: 0)])
        ])
        #expect(stitched.count == 2)
    }

    @Test func segmentStitcherCanFormClosedLoopPolyline() throws {
        let stitcher = SegmentStitcher2D(tolerance: 1e-9)
        let stitched = stitcher.stitch([
            .init(points: [.init(x: 0, y: 0), .init(x: 1, y: 0)]),
            .init(points: [.init(x: 1, y: 0), .init(x: 1, y: 1)]),
            .init(points: [.init(x: 1, y: 1), .init(x: 0, y: 1)]),
            .init(points: [.init(x: 0, y: 1), .init(x: 0, y: 0)])
        ])
        #expect(stitched.count == 1)
        #expect(stitched[0].points.count >= 4)
        let first = stitched[0].points.first
        let last = stitched[0].points.last
        #expect(hypot((first?.x ?? 10) - (last?.x ?? 20), (first?.y ?? 10) - (last?.y ?? 20)) < 1e-9)
    }

    @Test func implicitCircleProducesSegments() throws {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let sampler = ImplicitCurveSampler2D(
            options: .init(qualityProfile: .preview, xResolution: 64, yResolution: 64)
        )
        let set = sampler.sample(
            relation: relation,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func implicitCirclePointsApproximatelyOnCircle() throws {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let sampler = ImplicitCurveSampler2D(
            options: .init(qualityProfile: .balanced, xResolution: 96, yResolution: 96)
        )
        let set = sampler.sample(
            relation: relation,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        let points = set.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        let maxError = points.map { abs(($0.x * $0.x + $0.y * $0.y) - 1) }.max() ?? 10
        #expect(maxError < 0.2)
    }

    @Test func implicitStitchingReducesSegmentCountForCircle() throws {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )

        let rawSet = ImplicitCurveSampler2D(
            options: .init(
                qualityProfile: .balanced,
                xResolution: 96,
                yResolution: 96,
                enableSegmentStitching: false
            )
        ).sample(
            relation: relation,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        let stitchedSet = ImplicitCurveSampler2D(
            options: .init(
                qualityProfile: .balanced,
                xResolution: 96,
                yResolution: 96,
                enableSegmentStitching: true,
                stitchingTolerance: 1e-6
            )
        ).sample(
            relation: relation,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )

        #expect(!rawSet.segments.isEmpty)
        #expect(!stitchedSet.segments.isEmpty)
        #expect(stitchedSet.segments.count < rawSet.segments.count)
    }

    @Test func implicitNoStitchingKeepsMostlyTwoPointSegments() throws {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let set = ImplicitCurveSampler2D(
            options: .init(
                qualityProfile: .preview,
                xResolution: 48,
                yResolution: 48,
                enableSegmentStitching: false
            )
        ).sample(
            relation: relation,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        #expect(!set.segments.isEmpty)
        #expect(set.segments.allSatisfy { $0.points.count == 2 })
    }

    @Test func implicitStitchingPreservesIssueReporting() throws {
        let relation = Expr.equation(
            left: .divide(numerator: .integer(1), denominator: .integer(0)),
            right: .integer(0)
        )
        let set = ImplicitCurveSampler2D(
            options: .init(
                qualityProfile: .preview,
                xResolution: 32,
                yResolution: 32,
                enableSegmentStitching: true
            )
        ).sample(
            relation: relation,
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func implicitLineYEqualsXProducesSegments() throws {
        let relation = Expr.equation(
            left: .add([
                .symbol(Symbol(name: "y", role: .variable)),
                .negate(.symbol(Symbol(name: "x", role: .variable)))
            ]),
            right: .integer(0)
        )
        let set = ImplicitCurveSampler2D(
            options: .init(qualityProfile: .preview, xResolution: 64, yResolution: 64)
        ).sample(
            relation: relation,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        let points = set.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        let maxError = points.map { abs($0.y - $0.x) }.max() ?? 10
        #expect(maxError < 0.2)
    }

    @Test func implicitHyperbolaProducesSegments() throws {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .negate(.power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2)))
            ]),
            right: .integer(1)
        )
        let set = ImplicitCurveSampler2D(
            options: .init(qualityProfile: .balanced, xResolution: 128, yResolution: 128)
        ).sample(
            relation: relation,
            xRange: .init(lower: -3, upper: 3),
            yRange: .init(lower: -3, upper: 3)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func implicitXYEqualsOneProducesSegments() throws {
        let relation = Expr.equation(
            left: .multiply([
                .symbol(Symbol(name: "x", role: .variable)),
                .symbol(Symbol(name: "y", role: .variable))
            ]),
            right: .integer(1)
        )
        let set = ImplicitCurveSampler2D(
            options: .init(qualityProfile: .balanced, xResolution: 128, yResolution: 128)
        ).sample(
            relation: relation,
            xRange: .init(lower: -3, upper: 3),
            yRange: .init(lower: -3, upper: 3)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func implicitSinXYEqualsZeroDoesNotCrashAndReturnsDataOrIssues() throws {
        let relation = Expr.equation(
            left: .function(.sin, arguments: [
                .multiply([
                    .symbol(Symbol(name: "x", role: .variable)),
                    .symbol(Symbol(name: "y", role: .variable))
                ])
            ]),
            right: .integer(0)
        )
        let set = ImplicitCurveSampler2D(
            options: .init(qualityProfile: .balanced, xResolution: 96, yResolution: 96)
        ).sample(
            relation: relation,
            xRange: .init(lower: -3, upper: 3),
            yRange: .init(lower: -3, upper: 3)
        )
        #expect(!set.segments.isEmpty || !set.issues.isEmpty)
    }

    @Test func implicitEqualRelationIsSupported() throws {
        let relation = Expr.relation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            relation: .equal,
            right: .integer(1)
        )
        let set = ImplicitCurveSampler2D().sample(
            relation: relation,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func implicitNonEqualRelationUnsupported() throws {
        let relation = Expr.relation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            relation: .less,
            right: .symbol(Symbol(name: "y", role: .variable))
        )
        let set = ImplicitCurveSampler2D().sample(
            relation: relation,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func implicitInvalidXRange() throws {
        let set = ImplicitCurveSampler2D().sample(
            relation: .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: .integer(0)),
            xRange: .init(lower: 1, upper: 1),
            yRange: .init(lower: -1, upper: 1)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .invalidRange })
    }

    @Test func implicitInvalidYRange() throws {
        let set = ImplicitCurveSampler2D().sample(
            relation: .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: .integer(0)),
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: 0, upper: 0)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .invalidRange })
    }

    @Test func implicitInsufficientXResolution() throws {
        let set = ImplicitCurveSampler2D(
            options: .init(qualityProfile: .preview, xResolution: 1, yResolution: 16)
        ).sample(
            relation: .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: .integer(0)),
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .insufficientSamples })
    }

    @Test func implicitInsufficientYResolution() throws {
        let set = ImplicitCurveSampler2D(
            options: .init(qualityProfile: .preview, xResolution: 16, yResolution: 1)
        ).sample(
            relation: .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: .integer(0)),
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .insufficientSamples })
    }

    @Test func implicitUndefinedExpressionRecordsIssue() throws {
        let set = ImplicitCurveSampler2D().sample(
            relation: .equation(
                left: .divide(numerator: .integer(1), denominator: .integer(0)),
                right: .integer(0)
            ),
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func implicitNonFinitePointRecordsIssue() throws {
        let set = ImplicitCurveSampler2D(
            options: .init(qualityProfile: .preview, xResolution: 8, yResolution: 8, maxAbsCoordinate: 0.5)
        ).sample(
            relation: .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: .integer(0)),
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .nonFinitePoint })
    }

    @Test func graphIntentSamplerImplicitUsesImplicitCurveSampler() throws {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let set = GraphIntentSampler2D().sample(
            intent: .implicit(relation: relation),
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        #expect(!set.segments.isEmpty)
    }

    @Test func graphIntentSamplerImplicitNilYRangeReturnsInvalidRange() throws {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let set = GraphIntentSampler2D().sample(
            intent: .implicit(relation: relation),
            xRange: .init(lower: -2, upper: 2),
            yRange: nil
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .invalidRange })
    }

    @Test func piecewiseSamplerSupportsExplicitYBranches() throws {
        let x = Symbol(name: "x", role: .variable)
        let branches: [GraphIntentBranch] = [
            .init(
                condition: .relation(left: .symbol(x), relation: .less, right: .integer(0)),
                intent: .explicitY(
                    expression: .power(base: .symbol(x), exponent: .integer(2)),
                    variable: x
                )
            ),
            .init(
                condition: .relation(left: .symbol(x), relation: .greaterOrEqual, right: .integer(0)),
                intent: .explicitY(
                    expression: .symbol(x),
                    variable: x
                )
            )
        ]
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 9,
            maxSampleCount: 9,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let set = PiecewiseSampler2D(options: options).sampleY(
            branches: branches,
            variable: x,
            range: .init(lower: -1, upper: 1)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        #expect(points.contains { $0.x < 0 && abs($0.y - ($0.x * $0.x)) < 1e-8 })
        #expect(points.contains { $0.x >= 0 && abs($0.y - $0.x) < 1e-8 })
    }

    @Test func piecewiseBoundaryBreaksSegmentsAcrossBranches() throws {
        let x = Symbol(name: "x", role: .variable)
        let branches: [GraphIntentBranch] = [
            .init(
                condition: .relation(left: .symbol(x), relation: .less, right: .integer(0)),
                intent: .explicitY(expression: .power(base: .symbol(x), exponent: .integer(2)), variable: x)
            ),
            .init(
                condition: .relation(left: .symbol(x), relation: .greaterOrEqual, right: .integer(0)),
                intent: .explicitY(expression: .symbol(x), variable: x)
            )
        ]
        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 5,
            maxSampleCount: 5,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let set = PiecewiseSampler2D(options: options).sampleY(
            branches: branches,
            variable: x,
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.segments.count >= 2)
    }

    @Test func piecewiseUndefinedValueReportsEvaluationUndefined() throws {
        let x = Symbol(name: "x", role: .variable)
        let branches: [GraphIntentBranch] = [
            .init(
                condition: .relation(left: .symbol(x), relation: .greaterOrEqual, right: .integer(0)),
                intent: .explicitY(
                    expression: .divide(numerator: .integer(1), denominator: .integer(0)),
                    variable: x
                )
            )
        ]
        let set = PiecewiseSampler2D().sampleY(
            branches: branches,
            variable: x,
            range: .init(lower: 0, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .evaluationUndefined })
    }

    @Test func piecewiseUnsupportedBranchIntentReportsUnsupportedIntent() throws {
        let x = Symbol(name: "x", role: .variable)
        let branches: [GraphIntentBranch] = [
            .init(
                condition: .relation(left: .symbol(x), relation: .greaterOrEqual, right: .integer(0)),
                intent: .point(x: .integer(1), y: .integer(2))
            )
        ]
        let set = PiecewiseSampler2D().sampleY(
            branches: branches,
            variable: x,
            range: .init(lower: -1, upper: 1)
        )
        #expect(set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func graphIntentSamplerSupportsPiecewiseIntent() throws {
        let x = Symbol(name: "x", role: .variable)
        let intent = GraphIntent.piecewise([
            .init(
                condition: .relation(left: .symbol(x), relation: .less, right: .integer(0)),
                intent: .explicitY(expression: .power(base: .symbol(x), exponent: .integer(2)), variable: x)
            ),
            .init(
                condition: .relation(left: .symbol(x), relation: .greaterOrEqual, right: .integer(0)),
                intent: .explicitY(expression: .symbol(x), variable: x)
            )
        ])
        let set = GraphIntentSampler2D().sample(
            intent: intent,
            xRange: .init(lower: -1, upper: 1)
        )
        #expect(!set.segments.isEmpty)
        #expect(!set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func conicSamplerOriginEllipseGeneratesSamples() throws {
        let info = ConicInfo(
            kind: .ellipse,
            source: .unknown("ellipse"),
            canonicalForm: .originEllipse(a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        let hasNearCurvePoint = points.contains { p in
            abs((p.x * p.x) / 4.0 + (p.y * p.y) / 9.0 - 1.0) < 0.2
        }
        #expect(hasNearCurvePoint)
    }

    @Test func conicSamplerOriginHyperbolaXGeneratesTwoBranchesLikeSamples() throws {
        let info = ConicInfo(
            kind: .hyperbola,
            source: .unknown("hyperbolaX"),
            canonicalForm: .originHyperbolaX(a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        #expect(points.contains { $0.x > 0 })
        #expect(points.contains { $0.x < 0 })
        let hasNearCurvePoint = points.contains { p in
            abs((p.x * p.x) / 4.0 - (p.y * p.y) / 9.0 - 1.0) < 0.4
        }
        #expect(hasNearCurvePoint)
    }

    @Test func conicSamplerOriginHyperbolaYGeneratesSamples() throws {
        let info = ConicInfo(
            kind: .hyperbola,
            source: .unknown("hyperbolaY"),
            canonicalForm: .originHyperbolaY(a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let hasNearCurvePoint = points.contains { p in
            abs((p.y * p.y) / 9.0 - (p.x * p.x) / 4.0 - 1.0) < 0.4
        }
        #expect(hasNearCurvePoint)
    }

    @Test func conicSamplerWithoutCanonicalFormReturnsUnsupportedIntent() throws {
        let info = ConicInfo(kind: .ellipse, source: .unknown("missingCanonical"))
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func conicSamplerTranslatedEllipseGeneratesSamples() throws {
        let info = ConicInfo(
            kind: .ellipse,
            source: .unknown("translatedEllipse"),
            canonicalForm: .translatedEllipse(
                center: .tuple([.integer(1), .integer(2)]),
                a: .integer(2),
                b: .integer(3)
            ),
            orientation: .axisAligned
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let hasNearCurvePoint = points.contains { p in
            abs(((p.x - 1.0) * (p.x - 1.0)) / 4.0 + ((p.y - 2.0) * (p.y - 2.0)) / 9.0 - 1.0) < 0.2
        }
        #expect(hasNearCurvePoint)
    }

    @Test func conicSamplerTranslatedHyperbolaXGeneratesSamples() throws {
        let info = ConicInfo(
            kind: .hyperbola,
            source: .unknown("translatedHyperbolaX"),
            canonicalForm: .translatedHyperbolaX(
                center: .tuple([.integer(1), .integer(2)]),
                a: .integer(2),
                b: .integer(3)
            ),
            orientation: .axisAligned
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let hasNearCurvePoint = points.contains { p in
            abs(((p.x - 1.0) * (p.x - 1.0)) / 4.0 - ((p.y - 2.0) * (p.y - 2.0)) / 9.0 - 1.0) < 0.4
        }
        #expect(hasNearCurvePoint)
    }

    @Test func conicSamplerTranslatedHyperbolaYGeneratesSamples() throws {
        let info = ConicInfo(
            kind: .hyperbola,
            source: .unknown("translatedHyperbolaY"),
            canonicalForm: .translatedHyperbolaY(
                center: .tuple([.integer(1), .integer(2)]),
                a: .integer(2),
                b: .integer(3)
            ),
            orientation: .axisAligned
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let hasNearCurvePoint = points.contains { p in
            abs(((p.y - 2.0) * (p.y - 2.0)) / 9.0 - ((p.x - 1.0) * (p.x - 1.0)) / 4.0 - 1.0) < 0.4
        }
        #expect(hasNearCurvePoint)
    }

    @Test func conicSamplerTranslatedParabolaYGeneratesSamples() throws {
        let info = ConicInfo(
            kind: .parabola,
            source: .unknown("translatedParabolaY"),
            canonicalForm: .translatedParabolaY(
                vertex: .tuple([.integer(0), .integer(0)]),
                coefficient: .real(1)
            ),
            orientation: .axisAligned
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 4)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let hasNearCurvePoint = points.contains { p in
            abs(p.y - (p.x * p.x)) < 0.2
        }
        #expect(hasNearCurvePoint)
    }

    @Test func conicSamplerTranslatedParabolaXGeneratesSamples() throws {
        let info = ConicInfo(
            kind: .parabola,
            source: .unknown("translatedParabolaX"),
            canonicalForm: .translatedParabolaX(
                vertex: .tuple([.integer(0), .integer(0)]),
                coefficient: .real(1)
            ),
            orientation: .axisAligned
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let hasNearCurvePoint = points.contains { p in
            abs(p.x - (p.y * p.y)) < 0.2
        }
        #expect(hasNearCurvePoint)
    }

    @Test func conicSamplerParabolaInvalidVertexReturnsUnsupportedIntent() throws {
        let info = ConicInfo(
            kind: .parabola,
            source: .unknown("invalidParabolaVertex"),
            canonicalForm: .translatedParabolaY(
                vertex: .integer(0),
                coefficient: .real(1)
            ),
            orientation: .axisAligned
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        #expect(set.segments.isEmpty)
        #expect(set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func graphIntentSamplerSupportsConicIntent() throws {
        let info = ConicInfo(
            kind: .ellipse,
            source: .unknown("ellipse"),
            canonicalForm: .originEllipse(a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        let set = GraphIntentSampler2D().sample(
            intent: .conic(info),
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        #expect(!set.issues.contains { $0.kind == .unsupportedIntent })
    }

    @Test func conicSamplerRotatedEllipseGeneratesSamplesSatisfyingEquation() throws {
        let info = ConicInfo(
            kind: .ellipse,
            source: .unknown("rotatedEllipse"),
            canonicalForm: .translatedEllipse(
                center: .tuple([.real(0), .real(0)]),
                a: .function(.sqrt, arguments: [.real(0.5)]),
                b: .function(.sqrt, arguments: [.real(0.25)])
            ),
            orientation: .rotated,
            rotationAngle: 0.5 * Double.pi / 2.0 // π/4
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -3, upper: 3),
            yRange: .init(lower: -3, upper: 3)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let hasNearCurvePoint = points.contains { p in
            abs((p.x * p.x) + (2.0 * p.x * p.y) + (3.0 * p.y * p.y) - 1.0) < 0.35
        }
        #expect(hasNearCurvePoint)
    }

    @Test func conicSamplerRotatedHyperbolaGeneratesSamplesSatisfyingEquation() throws {
        let info = ConicInfo(
            kind: .hyperbola,
            source: .unknown("rotatedHyperbola"),
            canonicalForm: .translatedHyperbolaX(
                center: .tuple([.real(0), .real(0)]),
                a: .function(.sqrt, arguments: [.real(1.0 / 3.0)]),
                b: .function(.sqrt, arguments: [.real(1.0)])
            ),
            orientation: .rotated,
            rotationAngle: 0.5 * Double.pi / 2.0 // π/4
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -4, upper: 4),
            yRange: .init(lower: -4, upper: 4)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let hasNearCurvePoint = points.contains { p in
            abs((p.x * p.x) + (4.0 * p.x * p.y) + (p.y * p.y) - 1.0) < 0.6
        }
        #expect(hasNearCurvePoint)
    }

    @Test func rotatedConicSamplingDoesNotRegressAxisAlignedPath() throws {
        let info = ConicInfo(
            kind: .ellipse,
            source: .unknown("axisAligned"),
            canonicalForm: .translatedEllipse(
                center: .tuple([.integer(1), .integer(2)]),
                a: .integer(2),
                b: .integer(3)
            ),
            orientation: .axisAligned,
            rotationAngle: nil
        )
        let set = ConicSampler2D().sample(
            info: info,
            xRange: .init(lower: -10, upper: 10)
        )
        #expect(!set.segments.isEmpty)
        let points = set.segments.flatMap(\.points)
        let hasNearCurvePoint = points.contains { p in
            abs(((p.x - 1.0) * (p.x - 1.0)) / 4.0 + ((p.y - 2.0) * (p.y - 2.0)) / 9.0 - 1.0) < 0.25
        }
        #expect(hasNearCurvePoint)
    }

    @Test func sampleSetMapPointsTransformsAllPoints() throws {
        let original = SampleSet2D(
            segments: [
                SampleSegment2D(points: [
                    .init(x: 1, y: 2),
                    .init(x: 3, y: 4)
                ]),
                SampleSegment2D(points: [
                    .init(x: -1, y: -2)
                ])
            ],
            issues: []
        )
        let mapped = original.mapPoints { point in
            .init(x: point.x + 10, y: point.y - 10)
        }
        #expect(mapped.segments.count == 2)
        #expect(mapped.segments[0].points.count == 2)
        #expect(mapped.segments[1].points.count == 1)
        #expect(abs(mapped.segments[0].points[0].x - 11) < 1e-12)
        #expect(abs(mapped.segments[0].points[0].y - (-8)) < 1e-12)
        #expect(abs(mapped.segments[1].points[0].x - 9) < 1e-12)
        #expect(abs(mapped.segments[1].points[0].y - (-12)) < 1e-12)
    }

    @Test func sampleSetMapPointsPreservesIssues() throws {
        let original = SampleSet2D(
            segments: [SampleSegment2D(points: [.init(x: 0, y: 0)])],
            issues: [
                SamplingIssue(kind: .nonFinitePoint, message: "nf"),
                SamplingIssue(kind: .possibleDiscontinuity, message: "jump")
            ]
        )
        let mapped = original.mapPoints { point in point }
        #expect(mapped.issues == original.issues)
    }

    @Test func conicCoordinateTransformZeroAngleAppliesTranslationOnly() throws {
        let transform = ConicCoordinateTransform2D(
            centerX: 10,
            centerY: -3,
            rotationAngle: 0
        )
        let world = transform.transformLocalToWorld(.init(x: 1, y: 2))
        #expect(abs(world.x - 11) < 1e-12)
        #expect(abs(world.y - (-1)) < 1e-12)
    }

    @Test func conicCoordinateTransformNinetyDegreesRotatesCounterclockwise() throws {
        let transform = ConicCoordinateTransform2D(
            centerX: 5,
            centerY: 7,
            rotationAngle: Double.pi / 2
        )
        let world = transform.transformLocalToWorld(.init(x: 1, y: 0))
        #expect(abs(world.x - 5) < 1e-9)
        #expect(abs(world.y - 8) < 1e-9)
    }
}
