import CoreGraphics
import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct PlaneExplicitFunctionDiscontinuityTests {
    @Test func explicitFunctionOneOverXBreaksAtVerticalAsymptote() throws {
        let segments = try explicitSegments(for: "1/x", visibleWorldRect: .init(minX: -6, minY: -6, maxX: 6, maxY: 6))
        #expect(segments.count >= 2)
        #expect(bridgesVerticalLine(segments, x: 0) == false)
    }

    @Test func explicitFunctionShiftedReciprocalBreaksAtVerticalAsymptote() throws {
        let segments = try explicitSegments(for: "1/(x-1)", visibleWorldRect: .init(minX: -4, minY: -6, maxX: 4, maxY: 6))
        #expect(segments.count >= 2)
        #expect(bridgesVerticalLine(segments, x: 1) == false)
    }

    @Test func explicitFunctionTanBreaksNearAsymptotes() throws {
        let segments = try explicitSegments(
            for: "tan(x)",
            visibleWorldRect: .init(minX: -Double.pi, minY: -6, maxX: Double.pi, maxY: 6)
        )
        #expect(segments.count >= 3)
        #expect(bridgesVerticalLine(segments, x: Double.pi / 2) == false)
        #expect(bridgesVerticalLine(segments, x: -Double.pi / 2) == false)
    }

    @Test func continuousExplicitFunctionsRemainConnected() throws {
        let sinSegments = try explicitSegments(for: "sin(x)", visibleWorldRect: .init(minX: -6, minY: -6, maxX: 6, maxY: 6))
        let quadraticSegments = try explicitSegments(for: "x^2", visibleWorldRect: .init(minX: -3, minY: -1, maxX: 3, maxY: 10))
        #expect(sinSegments.count == 1)
        #expect(quadraticSegments.count == 1)
    }

    @Test func explicitDiscontinuityPreviewMatchesCommittedObject() throws {
        let state = workspaceState(title: "explicit-discontinuity-preview")
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("1/x"))

        let draft = try #require(state.draftMathObject)
        #expect(draft.previewSamples.count >= 2)
        #expect(bridgesVerticalLine(draft.previewSamples, x: 0) == false)

        state.dispatch(.submitInput)
        let objectID = try #require(state.selectedObjectID)
        let object = try #require(state.document.objects.first(where: { $0.id == objectID }))
        let committedSegments = try committedSegments(for: object, in: state.document)

        #expect(committedSegments.count == draft.previewSamples.count)
        #expect(bridgesVerticalLine(committedSegments, x: 0) == false)
    }

    @Test func projectPreviewRendererDoesNotConnectAsymptoteBranches() throws {
        let object = try committedFunctionObject(source: "1/(x-1)", title: "preview-legacy-segments")
        let segments = try #require(
            ProjectPreviewRenderer.legacyAlgebraSegmentsForTesting(
                for: object,
                visibleWorldRect: .init(minX: -4, minY: -6, maxX: 4, maxY: 6)
            )
        )
        #expect(segments.count >= 2)
        #expect(bridgesVerticalLine(segments.map { PlotSegment(points: $0) }, x: 1) == false)

        let preview = try #require(ProjectPreviewRenderer.renderPNGData(for: document(objects: [object], title: "preview-render")))
        #expect(preview.isEmpty == false)
    }
}

private extension PlaneExplicitFunctionDiscontinuityTests {
    func explicitSegments(for source: String, visibleWorldRect: WorldRect) throws -> [PlotSegment] {
        let analysis = AlgebraCore.analyzePlaneLatex(source.contains("=") ? source : "y=\(source)")
        let expression = try #require(analysis.classification.renderExpression)
        return PlaneLegacyExplicitSampling.sampleExplicitY(
            expression,
            visibleWorldRect: visibleWorldRect,
            samples: 700,
            parameterValues: [:]
        )
    }

    func committedSegments(for object: MathObject, in document: EMathicaDocument) throws -> [PlotSegment] {
        let expression = try #require(object.expression.algebraAnalysis?.classification.renderExpression)
        let rect = document.canvasState.visibleWorldRect(in: CGSize(width: 1024, height: 640))
        return PlaneLegacyExplicitSampling.sampleExplicitY(
            expression,
            visibleWorldRect: rect,
            samples: min(2600, max(320, Int(1024 / 1.4))),
            parameterValues: [:]
        )
    }

    func bridgesVerticalLine(_ segments: [PlotSegment], x: Double, epsilon: Double = 0.05) -> Bool {
        segments.contains { segment in
            let hasLeft = segment.points.contains { $0.x < x - epsilon }
            let hasRight = segment.points.contains { $0.x > x + epsilon }
            return hasLeft && hasRight
        }
    }

    func workspaceState(title: String) -> WorkspaceState {
        WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: title),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    func committedFunctionObject(source: String, title: String) throws -> MathObject {
        let state = workspaceState(title: title)
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText(source))
        state.dispatch(.submitInput)
        let objectID = try #require(state.selectedObjectID)
        return try #require(state.document.objects.first(where: { $0.id == objectID }))
    }

    func document(objects: [MathObject], title: String) -> EMathicaDocument {
        let now = Date()
        return EMathicaDocument(
            metadata: .init(
                title: title,
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: objects
        )
    }
}
