import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PiecewiseSemanticFlowTests {
    @Test func piecewiseTemplateLowersToExprPiecewise() {
        let template = TemplateNode(
            kind: .piecewise(rows: 2),
            fields: [
                .init(id: .rowExpression(0), node: .sequence([.character("x"), .operatorSymbol("^"), .character("2")])),
                .init(id: .rowCondition(0), node: .sequence([.character("x"), .operatorSymbol("<"), .character("0")])),
                .init(id: .rowExpression(1), node: .sequence([.character("x")])),
                .init(id: .rowCondition(1), node: .sequence([.character("x"), .operatorSymbol(">="), .character("0")]))
            ]
        )
        let root: MathNode = .sequence([.template(template)])

        let result = MathNodeSemanticLowering().lower(root)
        guard case .piecewise(let branches, let otherwise)? = result.expr else {
            Issue.record("Expected Expr.piecewise, got \(String(describing: result.expr))")
            return
        }
        #expect(otherwise == nil)
        #expect(branches.count == 2)
    }

    @Test func piecewiseTemplateSyncClassifiesAsGraphIntentPiecewise() {
        let template = TemplateNode(
            kind: .piecewise(rows: 2),
            fields: [
                .init(id: .rowExpression(0), node: .sequence([.character("x"), .operatorSymbol("^"), .character("2")])),
                .init(id: .rowCondition(0), node: .sequence([.character("x"), .operatorSymbol("<"), .character("0")])),
                .init(id: .rowExpression(1), node: .sequence([.character("x")])),
                .init(id: .rowCondition(1), node: .sequence([.character("x"), .operatorSymbol(">="), .character("0")]))
            ]
        )

        var input = FormulaInputState(
            editorState: EditorState(root: .sequence([.template(template)]))
        )
        input.syncDerivedStrings()

        guard case .piecewise(let branches)? = input.semanticState.graphClassification?.intent else {
            Issue.record("Expected GraphIntent.piecewise, got \(String(describing: input.semanticState.graphClassification?.intent))")
            return
        }
        #expect(branches.count == 2)
        #expect(branches.allSatisfy {
            if case .explicitY = $0.intent { return true }
            return false
        })
    }

    @Test func piecewiseThreeRowsClassifiesAllBranches() {
        let template = TemplateNode(
            kind: .piecewise(rows: 3),
            fields: [
                .init(id: .rowExpression(0), node: .sequence([.character("x"), .operatorSymbol("^"), .character("2")])),
                .init(id: .rowCondition(0), node: .sequence([.character("x"), .operatorSymbol("<"), .character("0")])),
                .init(id: .rowExpression(1), node: .sequence([.character("x")])),
                .init(id: .rowCondition(1), node: .sequence([.character("x"), .operatorSymbol(">"), .character("0")])),
                .init(id: .rowExpression(2), node: .sequence([.character("1")])),
                .init(id: .rowCondition(2), node: .sequence([.character("x"), .operatorSymbol("="), .character("0")]))
            ]
        )

        var input = FormulaInputState(
            editorState: EditorState(root: .sequence([.template(template)]))
        )
        input.syncDerivedStrings()

        guard case .piecewise(let branches)? = input.semanticState.graphClassification?.intent else {
            Issue.record("Expected GraphIntent.piecewise, got \(String(describing: input.semanticState.graphClassification?.intent))")
            return
        }
        #expect(branches.count == 3)
    }
}
