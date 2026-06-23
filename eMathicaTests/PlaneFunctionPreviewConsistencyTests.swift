import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct PlaneFunctionPreviewConsistencyTests {
    @Test func createSessionUpdatesDraftImmediatelyAndClearsOnCancel() throws {
        let state = makeWorkspaceState(objects: [])

        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("x^2"))

        let draft = try #require(state.draftMathObject)
        #expect(draft.sourceExpression == "x^2")
        #expect(draft.previewSamples.isEmpty == false)

        state.cancelFormulaEditing()
        #expect(state.draftMathObject == nil)
    }

    @Test func editSessionUpdatesDraftImmediatelyWithoutKeepingPreviousDraft() throws {
        let object = MathObject(
            name: "f_1",
            type: .function,
            expression: MathExpression(
                displayText: "x^2",
                sourceExpression: "x^2",
                computeExpression: "x^2"
            ),
            style: MathStyle(colorToken: "blue")
        )
        let state = makeWorkspaceState(objects: [object])

        state.beginEditingObjectExpression(object.id, openKeyboard: false)

        let initialDraft = try #require(state.draftMathObject)
        #expect(initialDraft.sourceExpression == "x^2")
        #expect(initialDraft.previewSamples.isEmpty == false)

        state.dispatch(.updateInputText("x^3"))

        let updatedDraft = try #require(state.draftMathObject)
        #expect(updatedDraft.sourceExpression == "x^3")
        #expect(updatedDraft.previewSamples.isEmpty == false)

        state.cancelFormulaEditing()
        #expect(state.draftMathObject == nil)
    }

    @Test func parseFailureStillProducesDraftWithDiagnostics() throws {
        let state = makeWorkspaceState(objects: [])

        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("sin("))

        let draft = try #require(state.draftMathObject)
        #expect(draft.parseError != nil)
        #expect(draft.diagnostics.isEmpty == false)
    }

    private func makeWorkspaceState(objects: [MathObject]) -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "Function Preview Test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: objects)
        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneWorkspaceModuleProvider().toolGroups,
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }
}
