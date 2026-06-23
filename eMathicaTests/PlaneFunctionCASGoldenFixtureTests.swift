import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct PlaneFunctionCASGoldenFixtureTests {
    @Test func functionCASFixtureCanBeBuilt() throws {
        let built = try PlaneFunctionCASFixture().build()

        #expect(built.document.objects.count == 8)
        #expect(Set(built.document.objects.map(\.id)).count == 8)
        #expect(Set(built.document.objects.map(\.name)).count == 8)
        #expect(built.cases.count == 8)
        #expect(built.document.objects.allSatisfy { $0.type == .function })

        for fixtureCase in built.cases {
            let object = try #require(built.document.object(id: fixtureCase.objectID))
            #expect(object.name == fixtureCase.name)
            #expect(object.expression.displayText.isEmpty == false)
            #expect(object.expression.rawInput == fixtureCase.expectedEditableSource)
            #expect(object.expression.sourceExpression == fixtureCase.expectedEditableSource)
            #expect(WorkspaceObjectExpressionDisplayResolver.primaryText(for: object) == object.expression.displayText)
        }
    }

    @Test func functionCASFixtureMetadataSurvivesSaveReopen() throws {
        let fixture = PlaneFunctionCASFixture()
        let built = try fixture.build()
        let reopened = try fixture.reopen(built.document)

        #expect(reopened.objects.count == 8)
        #expect(Set(reopened.objects.map(\.id)) == Set(built.cases.map(\.objectID)))

        for fixtureCase in built.cases {
            let reopenedObject = try #require(reopened.object(id: fixtureCase.objectID))
            #expect(reopenedObject.name == fixtureCase.name)
            #expect(reopenedObject.expression.rawInput == fixtureCase.expectedEditableSource)
            #expect(reopenedObject.expression.sourceExpression == fixtureCase.expectedEditableSource)
            #expect(reopenedObject.expression.originalLatex == fixtureCase.expectedOriginalLatex)
            #expect(reopenedObject.expression.displayText == fixtureCase.expectedDisplayText)
            #expect(reopenedObject.expression.editorASTData?.isEmpty == false)
            #expect(reopenedObject.expression.semanticGraphKind == fixtureCase.expectedSemanticKind)
            #expect(reopenedObject.expression.semanticParameterSymbol == fixtureCase.expectedParameterSymbol)
            #expect(reopenedObject.expression.semanticParameterRange == fixtureCase.expectedParameterRange)
        }
    }

    @Test func functionCASFixtureEditAfterReopenUsesEditableSourcePriority() throws {
        let fixture = PlaneFunctionCASFixture()
        let built = try fixture.build()
        let reopened = try fixture.reopen(built.document)
        let state = fixture.workspaceState(document: reopened)

        for fixtureCase in built.cases {
            state.beginEditingObjectExpression(fixtureCase.objectID, openKeyboard: false)
            #expect(state.formulaInputState.source == fixtureCase.expectedEditableSource)
            state.cancelFormulaEditing()
        }

        guard let reciprocal = built.fixtureCase(named: "f_4"),
              var reciprocalObject = reopened.object(id: reciprocal.objectID) else {
            Issue.record("Missing reciprocal fixture case")
            return
        }
        reciprocalObject.expression.editorASTData = nil

        let fallbackDocument = fixture.document(
            title: "Plane-Function-CAS-fallback",
            objects: reopened.objects.map { $0.id == reciprocalObject.id ? reciprocalObject : $0 }
        )
        let fallbackState = fixture.workspaceState(document: fallbackDocument)
        fallbackState.beginEditingObjectExpression(reciprocal.objectID, openKeyboard: false)
        #expect(fallbackState.formulaInputState.source == reciprocal.expectedEditableSource)
    }

    @Test func functionCASFixtureSemanticIntentRebuildsAfterReopen() throws {
        let fixture = PlaneFunctionCASFixture()
        let built = try fixture.build()
        let reopened = try fixture.reopen(built.document)

        for fixtureCase in built.cases {
            let reopenedObject = try #require(reopened.object(id: fixtureCase.objectID))
            let resolved = try #require(PlaneSemanticIntentResolver.resolveIntent(for: reopenedObject.expression))
            #expect(PlaneSemanticGraphIntentAdapter.semanticGraphKind(from: resolved) == fixtureCase.expectedSemanticKind)
            #expect(
                PlaneSemanticGraphIntentAdapter.parameterSymbol(from: resolved) == fixtureCase.expectedParameterSymbol
            )
            #expect(
                PlaneSemanticGraphIntentAdapter.parameterRange(from: resolved) == fixtureCase.expectedParameterRange
            )
        }
    }

    @Test func functionCASFixturePreviewRenders() throws {
        let fixture = PlaneFunctionCASFixture()
        let built = try fixture.build()
        let reopened = try fixture.reopen(built.document)

        let committedPreview = try #require(ProjectPreviewRenderer.renderPNGData(for: built.document))
        let reopenedPreview = try #require(ProjectPreviewRenderer.renderPNGData(for: reopened))

        #expect(committedPreview.isEmpty == false)
        #expect(reopenedPreview.isEmpty == false)
        #expect(committedPreview == reopenedPreview)
    }

    @Test func functionCASFixtureUnsupportedCasesAreDocumented() throws {
        let fixture = PlaneFunctionCASFixture()
        #expect(fixture.knownUnsupportedRawInputs == ["sqrt(x)"])

        let state = fixture.workspaceState(document: PlaneModule.newDocument(title: "unsupported"))
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("sqrt(x)"))
        state.dispatch(.submitInput)

        #expect(state.document.objects.isEmpty)
        let draft = try #require(state.draftMathObject)
        #expect(draft.parseError != nil || draft.diagnostics.isEmpty == false)
    }
}

@MainActor
private struct PlaneFunctionCASFixture {
    struct FixtureCase {
        let name: String
        let objectID: UUID
        let expectedEditableSource: String
        let expectedOriginalLatex: String
        let expectedDisplayText: String
        let expectedSemanticKind: SemanticGraphKind?
        let expectedParameterSymbol: Symbol?
        let expectedParameterRange: ParameterRange?
    }

    private struct CommittedSample {
        let input: String
        let expectedSemanticKind: SemanticGraphKind?
    }

    private struct StructuredSample {
        let expectedSemanticKind: SemanticGraphKind
        let input: FormulaInputState
    }

    struct BuiltFixture {
        let document: EMathicaDocument
        let cases: [FixtureCase]

        func fixtureCase(named name: String) -> FixtureCase? {
            cases.first(where: { $0.name == name })
        }
    }

    let knownUnsupportedRawInputs = ["sqrt(x)"]

    private var committedSamples: [CommittedSample] {
        [
            .init(input: "y=x", expectedSemanticKind: .explicitY),
            .init(input: "x^2", expectedSemanticKind: .explicitY),
            .init(input: "sin(x)", expectedSemanticKind: .explicitY),
            .init(input: "1/x", expectedSemanticKind: .explicitY),
            .init(input: "x^2+y^2=1", expectedSemanticKind: .circle)
        ]
    }

    private var structuredSamples: [StructuredSample] {
        [
            .init(expectedSemanticKind: .parametric2D, input: parametricCircleInput()),
            .init(expectedSemanticKind: .polar, input: polarRoseInput()),
            .init(expectedSemanticKind: .piecewise, input: piecewiseInput())
        ]
    }

    func build() throws -> BuiltFixture {
        let state = workspaceState(document: PlaneModule.newDocument(title: "Plane-Function-CAS"))
        var fixtureCases: [FixtureCase] = []

        for sample in committedSamples {
            state.dispatch(.openInput(mode: .expression))
            state.dispatch(.updateInputText(sample.input))

            let displayLatex = state.formulaInputState.displayLatex
            let editableSource = state.formulaInputState.source

            state.dispatch(.submitInput)

            guard let objectID = state.selectedObjectID,
                  let object = state.document.object(id: objectID) else {
                throw FixtureError.missingCommittedObject(sample.input)
            }

            fixtureCases.append(
                FixtureCase(
                    name: object.name,
                    objectID: object.id,
                    expectedEditableSource: editableSource,
                    expectedOriginalLatex: displayLatex,
                    expectedDisplayText: object.expression.displayText,
                    expectedSemanticKind: sample.expectedSemanticKind,
                    expectedParameterSymbol: object.expression.semanticParameterSymbol,
                    expectedParameterRange: object.expression.semanticParameterRange
                )
            )
        }

        var objects = state.document.objects
        for sample in structuredSamples {
            let object = functionObject(
                name: "f_\(objects.count + 1)",
                expression: makeStructuredExpression(from: sample.input)
            )
            objects.append(object)
            fixtureCases.append(
                FixtureCase(
                    name: object.name,
                    objectID: object.id,
                    expectedEditableSource: sample.input.source,
                    expectedOriginalLatex: sample.input.displayLatex,
                    expectedDisplayText: object.expression.displayText,
                    expectedSemanticKind: sample.expectedSemanticKind,
                    expectedParameterSymbol: object.expression.semanticParameterSymbol,
                    expectedParameterRange: object.expression.semanticParameterRange
                )
            )
        }

        let document = self.document(title: "Plane-Function-CAS", objects: objects)
        return BuiltFixture(document: document, cases: fixtureCases)
    }

    func workspaceState(document: EMathicaDocument) -> WorkspaceState {
        WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    func reopen(_ document: EMathicaDocument) throws -> EMathicaDocument {
        let data = try EMathicaPackageCodec.makeEncoder().encode(document)
        return try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)
    }

    func document(title: String, objects: [MathObject]) -> EMathicaDocument {
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

    private func functionObject(name: String, expression: MathExpression) -> MathObject {
        MathObject(
            name: name,
            type: .function,
            expression: expression,
            style: MathStyle(colorToken: "blue")
        )
    }

    private func makeStructuredExpression(from input: FormulaInputState) -> MathExpression {
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

    private func editorASTData(for state: EditorState) -> String {
        let data = try! JSONEncoder().encode(state)
        return String(decoding: data, as: UTF8.self)
    }

    private func parametricCircleInput() -> FormulaInputState {
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

    private func polarRoseInput() -> FormulaInputState {
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

    private func piecewiseInput() -> FormulaInputState {
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

    private func functionCall(_ name: String, argument: String) -> MathNode {
        .sequence([
            .character(String(name[name.startIndex])),
            .character(String(name[name.index(after: name.startIndex)])),
            .character(String(name[name.index(name.startIndex, offsetBy: 2)])),
            .template(TemplateNode(kind: .parentheses, fields: [
                .init(id: .content, node: .sequence(argument.map { .character(String($0)) }))
            ]))
        ])
    }

    private enum FixtureError: Error {
        case missingCommittedObject(String)
    }
}

private extension EMathicaDocument {
    func object(id: UUID) -> MathObject? {
        objects.first(where: { $0.id == id })
    }
}
