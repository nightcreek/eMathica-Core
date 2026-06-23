import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct PlaneFunctionMetadataSaveLoadTests {
    @Test func functionRawInputOriginalLatexDisplayTextSurviveSaveReopen() throws {
        for sample in committedFunctionSamples {
            let committed = try commitFunction(sample.input, title: sample.title)
            let committedObject = committed.object
            let reopenedDocument = try reopen(committed.state.document)
            let reopenedObject = try #require(reopenedDocument.object(id: committedObject.id))

            #expect(committedObject.type == .function)
            #expect(committedObject.expression.sourceExpression == committed.editableSource)
            #expect(committedObject.expression.rawInput == committed.editableSource)
            #expect(committedObject.expression.originalLatex == committed.displayLatex)
            #expect(committedObject.expression.displayText.isEmpty == false)
            #expect(committedObject.expression.editorASTData?.isEmpty == false)
            #expect(committedObject.expression.algebraAnalysis != nil)

            #expect(reopenedObject.expression.sourceExpression == committed.editableSource)
            #expect(reopenedObject.expression.rawInput == committed.editableSource)
            #expect(reopenedObject.expression.originalLatex == committed.displayLatex)
            #expect(reopenedObject.expression.displayText == committedObject.expression.displayText)
            #expect(reopenedObject.expression.editorASTData == committedObject.expression.editorASTData)
            #expect(reopenedObject.expression.algebraAnalysis == committedObject.expression.algebraAnalysis)
            #expect(WorkspaceObjectExpressionDisplayResolver.primaryText(for: reopenedObject) == reopenedObject.expression.displayText)

            let reopenedState = workspaceState(document: reopenedDocument)
            reopenedState.beginEditingObjectExpression(reopenedObject.id, openKeyboard: false)
            #expect(reopenedState.formulaInputState.source == committed.editableSource)

            let reopenedDraft = try #require(reopenedState.draftMathObject)
            #expect(reopenedDraft.sourceExpression == committed.editableSource)
            #expect(reopenedDraft.previewSamples.isEmpty == false)
        }
    }

    @Test func missingEditorASTDataFallsBackToEditablePriorityChain() throws {
        let prefersSource = MathObject(
            name: "f_1",
            type: .function,
            expression: MathExpression(
                displayText: "y = sin(x)",
                rawInput: "y=sin(x)",
                originalLatex: "sin(x)",
                sourceExpression: "sin(x)"
            ),
            style: MathStyle(colorToken: "blue")
        )
        let prefersRaw = MathObject(
            name: "f_2",
            type: .function,
            expression: MathExpression(
                displayText: "y = sin(x)",
                rawInput: "y=sin(x)",
                originalLatex: "sin(x)"
            ),
            style: MathStyle(colorToken: "blue")
        )
        let prefersLatex = MathObject(
            name: "f_3",
            type: .function,
            expression: MathExpression(
                displayText: "y = sin(x)",
                originalLatex: "sin(x)"
            ),
            style: MathStyle(colorToken: "blue")
        )

        let reopenedDocument = try reopen(document(objects: [prefersSource, prefersRaw, prefersLatex], title: "missing-ast"))
        let state = workspaceState(document: reopenedDocument)

        state.beginEditingObjectExpression(prefersSource.id, openKeyboard: false)
        #expect(state.formulaInputState.source == "sin(x)")
        state.cancelFormulaEditing()

        state.beginEditingObjectExpression(prefersRaw.id, openKeyboard: false)
        #expect(state.formulaInputState.source == "y=sin(x)")
        state.cancelFormulaEditing()

        state.beginEditingObjectExpression(prefersLatex.id, openKeyboard: false)
        #expect(state.formulaInputState.source == "sin(x)")
    }

    @Test func corruptEditorASTDataFallsBackWithoutCrash() throws {
        let object = MathObject(
            name: "f_1",
            type: .function,
            expression: MathExpression(
                displayText: "y = sin(x)",
                rawInput: "y=sin(x)",
                originalLatex: "sin(x)",
                editorASTData: "{invalid-json",
                sourceExpression: "sin(x)"
            ),
            style: MathStyle(colorToken: "blue")
        )

        let reopenedDocument = try reopen(document(objects: [object], title: "corrupt-ast"))
        let reopenedObject = try #require(reopenedDocument.object(id: object.id))
        let state = workspaceState(document: reopenedDocument)

        state.beginEditingObjectExpression(reopenedObject.id, openKeyboard: false)
        #expect(state.formulaInputState.source == "sin(x)")
        #expect(state.formulaInputState.semanticState.expression != nil)

        let preview = try #require(ProjectPreviewRenderer.renderPNGData(for: reopenedDocument))
        #expect(preview.isEmpty == false)
    }

    @Test func functionPreviewAfterReopenMatchesCommitPath() throws {
        for sample in previewConsistencySamples {
            let committed = try commitFunction(sample.input, title: "preview-\(sample.title)")
            let committedDocument = committed.state.document
            let reopenedDocument = try reopen(committedDocument)

            let committedPreview = try #require(ProjectPreviewRenderer.renderPNGData(for: committedDocument))
            let reopenedPreview = try #require(ProjectPreviewRenderer.renderPNGData(for: reopenedDocument))
            #expect(committedPreview.isEmpty == false)
            #expect(reopenedPreview.isEmpty == false)
            #expect(committedPreview == reopenedPreview)
        }
    }

    @Test func structuredFunctionMetadataSurvivesSaveReopenAndSemanticIntentRebuilds() throws {
        for sample in structuredSamples {
            let object = functionObject(name: sample.name, expression: makeStructuredExpression(from: sample.input))
            let reopenedDocument = try reopen(document(objects: [object], title: sample.name))
            let reopenedObject = try #require(reopenedDocument.object(id: object.id))

            #expect(reopenedObject.expression.rawInput == sample.input.source)
            #expect(reopenedObject.expression.originalLatex == sample.input.displayLatex)
            #expect(reopenedObject.expression.editorASTData == object.expression.editorASTData)
            #expect(reopenedObject.expression.semanticGraphKind == object.expression.semanticGraphKind)
            #expect(reopenedObject.expression.semanticParameterSymbol == object.expression.semanticParameterSymbol)
            #expect(reopenedObject.expression.semanticParameterRange == object.expression.semanticParameterRange)

            let resolvedIntent = try #require(PlaneSemanticIntentResolver.resolveIntent(for: reopenedObject.expression))
            switch (sample.expectedKind, resolvedIntent) {
            case (.parametric2D, .parametric2D):
                break
            case (.polar, .polar):
                break
            case (.piecewise, .piecewise):
                break
            default:
                Issue.record("Unexpected semantic intent for \(sample.name): \(resolvedIntent)")
            }

            let reopenedState = workspaceState(document: reopenedDocument)
            reopenedState.beginEditingObjectExpression(reopenedObject.id, openKeyboard: false)
            #expect(reopenedState.formulaInputState.source == sample.input.source)

            let preview = try #require(ProjectPreviewRenderer.renderPNGData(for: reopenedDocument))
            #expect(preview.isEmpty == false)
        }
    }
}

private extension PlaneFunctionMetadataSaveLoadTests {
    struct CommittedSample {
        let title: String
        let input: String
    }

    struct StructuredSample {
        let name: String
        let expectedKind: SemanticGraphKind
        let input: FormulaInputState
    }

    var committedFunctionSamples: [CommittedSample] {
        [
            .init(title: "explicit-y-equality", input: "y=x"),
            .init(title: "explicit-y-bare-quadratic", input: "x^2"),
            .init(title: "explicit-y-bare-sine", input: "sin(x)"),
            .init(title: "explicit-y-tangent", input: "tan(x)"),
            .init(title: "explicit-y-reciprocal", input: "1/x"),
            .init(title: "implicit-circle", input: "x^2+y^2=1")
        ]
    }

    var previewConsistencySamples: [CommittedSample] {
        [
            .init(title: "quadratic", input: "x^2"),
            .init(title: "sine", input: "sin(x)"),
            .init(title: "reciprocal", input: "1/x"),
            .init(title: "implicit-circle", input: "x^2+y^2=1")
        ]
    }

    var structuredSamples: [StructuredSample] {
        [
            .init(name: "parametric-circle", expectedKind: .parametric2D, input: parametricCircleInput()),
            .init(name: "polar-rose", expectedKind: .polar, input: polarRoseInput()),
            .init(name: "piecewise-two-branch", expectedKind: .piecewise, input: piecewiseInput())
        ]
    }

    func commitFunction(_ source: String, title: String) throws -> (state: WorkspaceState, object: MathObject, displayLatex: String, editableSource: String) {
        let state = workspaceState(document: PlaneModule.newDocument(title: title))
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText(source))
        let displayLatex = state.formulaInputState.displayLatex
        let editableSource = state.formulaInputState.source
        state.dispatch(.submitInput)

        guard let objectID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == objectID }) else {
            throw FixtureError.missingCommittedObject(source)
        }
        return (state, object, displayLatex, editableSource)
    }

    func workspaceState(document: EMathicaDocument) -> WorkspaceState {
        WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    func document(objects: [MathObject], title: String) -> EMathicaDocument {
        let now = Date()
        return EMathicaDocument(
            metadata: ProjectMetadata(
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

    func reopen(_ document: EMathicaDocument) throws -> EMathicaDocument {
        let data = try EMathicaPackageCodec.makeEncoder().encode(document)
        return try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)
    }

    func functionObject(name: String, expression: MathExpression) -> MathObject {
        MathObject(
            name: name,
            type: .function,
            expression: expression,
            style: MathStyle(colorToken: "blue")
        )
    }

    func makeStructuredExpression(from input: FormulaInputState) -> MathExpression {
        let intent = input.semanticState.graphClassification?.intent
        return MathExpression(
            displayText: input.source,
            rawInput: input.source,
            originalLatex: input.displayLatex,
            semanticGraphKind: PlaneSemanticGraphIntentAdapter.semanticGraphKind(from: intent),
            semanticParameterSymbol: PlaneSemanticGraphIntentAdapter.parameterSymbol(from: intent),
            semanticParameterRange: PlaneSemanticGraphIntentAdapter.parameterRange(from: intent),
            editorASTData: editorASTData(for: input.editorState),
            sourceExpression: input.source,
            computeExpression: input.computeExpression
        )
    }

    func editorASTData(for state: EditorState) -> String {
        let data = try! JSONEncoder().encode(state)
        return String(decoding: data, as: UTF8.self)
    }

    func parametricCircleInput() -> FormulaInputState {
        let template = TemplateNode(
            kind: .parametricEquation2D,
            fields: [
                .init(id: .parametricExpression(0), node: functionCall("cos", argument: "t")),
                .init(id: .parametricExpression(1), node: functionCall("sin", argument: "t")),
                .init(
                    id: .parametricRange,
                    node: .sequence([
                        .character("0"), .operatorSymbol("<="), .character("t"), .operatorSymbol("<="), .character("2"), .character("π")
                    ])
                )
            ]
        )
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(template)])))
        input.syncDerivedStrings()
        return input
    }

    func polarRoseInput() -> FormulaInputState {
        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [
                .init(id: .content, node: .sequence([.character("3"), .character("θ")]))
            ])),
            .character(","),
            .character("0"), .operatorSymbol("<="), .character("θ"), .operatorSymbol("<="), .character("2"), .character("π")
        ])
        let braces = TemplateNode(kind: .braces, fields: [.init(id: .content, node: content)])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()
        return input
    }

    func piecewiseInput() -> FormulaInputState {
        let template = TemplateNode(
            kind: .piecewise(rows: 2),
            fields: [
                .init(id: .rowExpression(0), node: .sequence([.character("x"), .operatorSymbol("^"), .character("2")])),
                .init(id: .rowCondition(0), node: .sequence([.character("x"), .operatorSymbol("<"), .character("0")])),
                .init(id: .rowExpression(1), node: .sequence([.character("x")])),
                .init(id: .rowCondition(1), node: .sequence([.character("x"), .operatorSymbol(">"), .operatorSymbol("="), .character("0")]))
            ]
        )
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(template)])))
        input.syncDerivedStrings()
        return input
    }

    func functionCall(_ name: String, argument: String) -> MathNode {
        .sequence(
            name.map { MathNode.character(String($0)) } + [
                .template(TemplateNode(kind: .parentheses, fields: [
                    .init(id: .content, node: .sequence(argument.map { .character(String($0)) }))
                ]))
            ]
        )
    }
}

private enum FixtureError: Error {
    case missingCommittedObject(String)
}

private extension EMathicaDocument {
    func object(id: UUID) -> MathObject? {
        objects.first(where: { $0.id == id })
    }
}
