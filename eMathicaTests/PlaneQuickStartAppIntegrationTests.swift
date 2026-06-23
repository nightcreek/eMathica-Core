import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct PlaneQuickStartAppIntegrationTests {
    @Test func quickStartTemplatesOnlyAppearInPlaneWorkspace() {
        let planeState = makePlaneWorkspaceState(objects: [])
        let spaceState = makeSpaceWorkspaceState(objects: [])

        #expect(planeState.canShowQuickStartExpressionTemplates == true)
        #expect(spaceState.canShowQuickStartExpressionTemplates == false)

        planeState.startQuickStartExpressionTemplate(.explicitFunction, openKeyboard: false)
        #expect(planeState.canShowQuickStartExpressionTemplates == true)

        let existing = MathObject(
            name: "f",
            type: .function,
            expression: MathExpression(displayText: "y=x"),
            style: MathStyle(colorToken: "blue")
        )
        let editingState = makePlaneWorkspaceState(objects: [existing])
        editingState.beginEditingObjectExpression(existing.id, openKeyboard: false)
        #expect(editingState.canShowQuickStartExpressionTemplates == false)
    }

    @Test func quickStartTemplatesReachDraftPreviewPath() async throws {
        let expectations: [(QuickStartExpressionTemplate, SemanticGraphKind)] = [
            (.explicitFunction, .explicitY),
            (.parametricCurve, .parametric2D),
            (.polarCurve, .polar),
            (.point, .point),
        ]

        for (template, expectedKind) in expectations {
            let state = makePlaneWorkspaceState(objects: [])
            state.startQuickStartExpressionTemplate(template, openKeyboard: false)

            try await Task.sleep(for: .milliseconds(180))

            #expect(state.formulaInputState.source == template.previewText)
            #expect(state.formulaEditSession?.mode == .createNew)
            #expect(state.draftMathObject != nil)
            #expect(state.draftMathObject?.parseError == nil)
            #expect(state.draftMathObject?.previewSamples.isEmpty == false)
            #expect(state.draftMathObject?.algebraAnalysis?.displayText.isEmpty == false)
            #expect(state.formulaInputState.semanticState.graphClassification?.intent != nil)
            #expect(state.formulaInputState.semanticState.graphClassification.map { semanticKind(for: $0.intent) } == expectedKind)
        }
    }

    @Test func quickStartTemplatesReachCommittedObjectCreationPath() async throws {
        let expectations: [(QuickStartExpressionTemplate, SemanticGraphKind, MathObjectType)] = [
            (.explicitFunction, .explicitY, .function),
            (.parametricCurve, .parametric2D, .function),
            (.polarCurve, .polar, .function),
            (.point, .point, .point),
        ]

        for (template, expectedKind, expectedType) in expectations {
            let state = makePlaneWorkspaceState(objects: [])
            state.startQuickStartExpressionTemplate(template, openKeyboard: false)

            try await Task.sleep(for: .milliseconds(180))
            state.commitFormulaEditing()

            #expect(state.commitErrorMessage == nil)
            #expect(state.document.objects.count == 1)
            guard let object = state.document.objects.first else {
                Issue.record("Expected committed object for template \(template.rawValue)")
                continue
            }
            #expect(object.type == expectedType)
            #expect(object.expression.semanticGraphKind == expectedKind)
            #expect(object.expression.sourceExpression == template.previewText)
            #expect(state.selectedObjectIDs == [object.id])
        }
    }

    private func makePlaneWorkspaceState(objects: [MathObject]) -> WorkspaceState {
        let provider = PlaneWorkspaceModuleProvider()
        return WorkspaceState(
            module: .plane,
            document: makeDocument(moduleID: "plane", title: "Plane Quick Start Integration Test", objects: objects),
            toolGroups: provider.toolGroups,
            moduleProvider: provider
        )
    }

    private func makeSpaceWorkspaceState(objects: [MathObject]) -> WorkspaceState {
        let provider = SpaceWorkspaceModuleProvider()
        return WorkspaceState(
            module: .space,
            document: makeDocument(moduleID: "space", title: "Space Quick Start Integration Test", objects: objects),
            toolGroups: provider.toolGroups,
            moduleProvider: provider
        )
    }

    private func makeDocument(moduleID: String, title: String, objects: [MathObject]) -> EMathicaDocument {
        let now = Date()
        let metadata = ProjectMetadata(
            title: title,
            moduleID: moduleID,
            createdAt: now,
            updatedAt: now,
            calculatorType: moduleID
        )
        return EMathicaDocument(metadata: metadata, moduleID: moduleID, objects: objects)
    }

    private func semanticKind(for intent: GraphIntent) -> SemanticGraphKind {
        PlaneSemanticGraphIntentAdapter.semanticGraphKind(from: intent) ?? .unknown
    }
}
