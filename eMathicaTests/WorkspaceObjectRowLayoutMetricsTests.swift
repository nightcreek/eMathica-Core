import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct WorkspaceObjectRowLayoutMetricsTests {
    @Test func primaryDisplayTextPrefersUserFacingFieldsInOrder() {
        let displayFirst = MathObject(
            name: "f",
            type: .function,
            expression: MathExpression(displayText: "f(x) = x^2", rawInput: "raw", originalLatex: "\\text{ignored}"),
            style: MathStyle(colorToken: "blue")
        )
        #expect(WorkspaceObjectExpressionDisplayResolver.primaryText(for: displayFirst) == "f(x) = x^2")

        let originalLatexOnly = MathObject(
            name: "g",
            type: .function,
            expression: MathExpression(displayText: " ", rawInput: "raw", originalLatex: "\\frac{x}{2}"),
            style: MathStyle(colorToken: "blue")
        )
        #expect(WorkspaceObjectExpressionDisplayResolver.primaryText(for: originalLatexOnly) == "\\frac{x}{2}")

        let rawOnly = MathObject(
            name: "h",
            type: .function,
            expression: MathExpression(displayText: " ", rawInput: "x^2 + 1", originalLatex: " "),
            style: MathStyle(colorToken: "blue")
        )
        #expect(WorkspaceObjectExpressionDisplayResolver.primaryText(for: rawOnly) == "x^2 + 1")

        let nameFallback = MathObject(
            name: "k",
            type: .function,
            expression: MathExpression(displayText: " ", rawInput: " ", originalLatex: " "),
            style: MathStyle(colorToken: "blue")
        )
        #expect(WorkspaceObjectExpressionDisplayResolver.primaryText(for: nameFallback) == "k")
    }

    @Test func fallbackTextUsesSingleLineScrollableDisplay() {
        let shortLimit = WorkspaceObjectFormulaDisplayMetrics.fallbackLineLimit(
            allowsMultiline: false,
            fallbackText: "y = x^2"
        )
        let longLimit = WorkspaceObjectFormulaDisplayMetrics.fallbackLineLimit(
            allowsMultiline: false,
            fallbackText: "y = \\frac{x^2 + 2x + 1}{x - 1} + \\sin(x)"
        )
        #expect(shortLimit == 1)
        #expect(longLimit == 1)
    }

    @Test func multilineFormulaUsesLargerDisplayScaleThanCompactSingleLine() {
        let compactScale = WorkspaceObjectFormulaDisplayMetrics.scaleFactor(allowsMultiline: false)
        let multilineScale = WorkspaceObjectFormulaDisplayMetrics.scaleFactor(allowsMultiline: true)
        #expect(multilineScale > compactScale)
    }

    @Test func piecewiseTwoRowsHeightIsAtLeastBaseHeight() {
        let state = piecewiseState(rows: 2)
        let height = WorkspaceObjectRowLayoutMetrics.formulaMinHeight(
            semanticGraphKind: .piecewise,
            editorState: state,
            fallbackText: "piecewise"
        )
        #expect(height >= 24)
    }

    @Test func piecewiseThreeRowsHeightIsGreaterThanTwoRows() {
        let two = WorkspaceObjectRowLayoutMetrics.formulaMinHeight(
            semanticGraphKind: .piecewise,
            editorState: piecewiseState(rows: 2),
            fallbackText: "piecewise"
        )
        let three = WorkspaceObjectRowLayoutMetrics.formulaMinHeight(
            semanticGraphKind: .piecewise,
            editorState: piecewiseState(rows: 3),
            fallbackText: "piecewise"
        )
        #expect(three > two)
    }

    @Test func piecewiseFourRowsHeightIsGreaterThanThreeRows() {
        let three = WorkspaceObjectRowLayoutMetrics.formulaMinHeight(
            semanticGraphKind: .piecewise,
            editorState: piecewiseState(rows: 3),
            fallbackText: "piecewise"
        )
        let four = WorkspaceObjectRowLayoutMetrics.formulaMinHeight(
            semanticGraphKind: .piecewise,
            editorState: piecewiseState(rows: 4),
            fallbackText: "piecewise"
        )
        #expect(four > three)
    }

    @Test func piecewiseAllowsMultilineFormulaDisplay() {
        let multiline = WorkspaceObjectRowLayoutMetrics.allowsMultilineFormula(
            semanticGraphKind: .piecewise,
            editorState: piecewiseState(rows: 3),
            fallbackText: "piecewise"
        )
        #expect(multiline)
    }

    @Test func explicitYKeepsCompactFormulaHeight() {
        let height = WorkspaceObjectRowLayoutMetrics.formulaMinHeight(
            semanticGraphKind: .explicitY,
            editorState: nil,
            fallbackText: "y=x^2"
        )
        #expect(height == 24)
    }

    @Test func parametricKeepsCompactFormulaHeight() {
        let height = WorkspaceObjectRowLayoutMetrics.formulaMinHeight(
            semanticGraphKind: .parametric2D,
            editorState: nil,
            fallbackText: "{x=t,y=t^2}"
        )
        #expect(height == 24)
    }

    private func piecewiseState(rows: Int) -> EditorState {
        var fields: [TemplateField] = []
        for row in 0..<rows {
            fields.append(.init(id: .rowExpression(row), node: .sequence([.character("x")])))
            fields.append(.init(id: .rowCondition(row), node: .sequence([.character("x"), .operatorSymbol("<"), .character(String(row + 1))])))
        }
        let template = TemplateNode(kind: .piecewise(rows: rows), fields: fields)
        return EditorState(root: .sequence([.template(template)]))
    }
}
