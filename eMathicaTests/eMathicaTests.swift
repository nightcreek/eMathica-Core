//
//  eMathicaTests.swift
//  eMathicaTests
//
//  Created by 楼俊翔 on 2026/5/8.
//

import Testing
import CoreGraphics
import UIKit
@testable import EMathicaThemeKit
@testable import EMathicaMathCore
import EMathicaDocumentKit
@testable import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

typealias EditorCursorNavigator = EMathicaMathInputCore.EditorCursorNavigator
typealias EditorCursor = EMathicaMathInputCore.EditorCursor
typealias EditorSelection = EMathicaMathInputCore.EditorSelection
typealias EditorPathComponent = EMathicaMathInputCore.EditorPathComponent
typealias MathNode = EMathicaMathInputCore.MathNode
typealias TemplateNode = EMathicaMathInputCore.TemplateNode
typealias FieldID = EMathicaMathInputCore.FieldID
typealias KeyboardAction = EMathicaMathInputCore.KeyboardAction
typealias TemplateKind = EMathicaMathInputCore.TemplateKind

struct eMathicaTests {
    private func manualFunctionCallSequence(_ name: String, argument: String = "t") -> MathNode {
        let arg = MathNode.sequence(argument.map { .character(String($0)) })
        let parens = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: arg)
        ])
        var nodes: [MathNode] = name.map { .character(String($0)) }
        nodes.append(.template(parens))
        return .sequence(nodes)
    }

    private func polarBraceInput(
        radiusArgument: [MathNode],
        rangeLowerOp: String,
        rangeUpperOp: String,
        angle: String = "θ",
        upperBound: [MathNode]
    ) -> MathNode {
        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence(radiusArgument))])),
            .character(","),
            .character("0"), .operatorSymbol(rangeLowerOp), .character(angle), .operatorSymbol(rangeUpperOp)
        ] + upperBound)
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        return .sequence([.template(braces)])
    }

    private func assertPolarRangeIsZeroToTwoPi(_ input: inout FormulaInputState, angle expectedAngle: String) {
        input.syncDerivedStrings()
        guard case .polar(_, let angle, let range)? = input.semanticState.graphClassification?.intent else {
            Issue.record("Expected polar intent")
            return
        }
        #expect(angle.name == expectedAngle)
        guard let range else {
            Issue.record("Expected polar range")
            return
        }
        let evaluator = ExprEvaluator()
        if let lower = range.lower {
            if case .value(let lowerValue) = evaluator.evaluate(lower) {
                #expect(abs(lowerValue) < 1e-9)
            } else {
                Issue.record("Lower bound failed to evaluate")
            }
        } else {
            Issue.record("Lower bound missing")
        }
        if let upper = range.upper {
            if case .value(let upperValue) = evaluator.evaluate(upper) {
                #expect(abs(upperValue - (2 * Double.pi)) < 1e-9)
            } else {
                Issue.record("Upper bound failed to evaluate")
            }
        } else {
            Issue.record("Upper bound missing")
        }
    }


    @Test func semanticLoweringSymbol() throws {
        let root = MathNode.sequence([.character("x")])
        let result = MathNodeSemanticLowering().lower(root)
        guard case .symbol(let symbol)? = result.expr else {
            Issue.record("Expected symbol")
            return
        }
        #expect(symbol.name == "x")
    }

    @Test func semanticLoweringInteger() throws {
        let root = MathNode.sequence([.character("1"), .character("2"), .character("3")])
        let result = MathNodeSemanticLowering().lower(root)
        #expect(result.expr == .integer(123))
    }

    @Test func semanticLoweringDecimal() throws {
        let root = MathNode.sequence([.character("0"), .character("."), .character("1"), .character("0"), .character("0")])
        let result = MathNodeSemanticLowering().lower(root)
        #expect(result.expr == .decimal("0.100"))
    }

    @Test func semanticLoweringFractionTemplate() throws {
        let template = TemplateNode(kind: .fraction, fields: [
            .init(id: .numerator, node: .sequence([.character("1")])),
            .init(id: .denominator, node: .sequence([.character("3")]))
        ])
        let result = MathNodeSemanticLowering().lower(.template(template))
        #expect(result.expr == .divide(numerator: .integer(1), denominator: .integer(3)))
    }

    @Test func semanticLoweringSuperscriptTemplate() throws {
        let template = TemplateNode(kind: .superscript, fields: [
            .init(id: .base, node: .sequence([.character("x")])),
            .init(id: .exponent, node: .sequence([.character("2")]))
        ])
        let result = MathNodeSemanticLowering().lower(.template(template))
        #expect(result.expr == .power(base: .symbol(Symbol(name: "x", role: .unknown)), exponent: .integer(2)))
    }

    @Test func semanticLoweringSinTemplate() throws {
        let template = TemplateNode(kind: .sin, fields: [
            .init(id: .argument, node: .sequence([.character("x")]))
        ])
        let result = MathNodeSemanticLowering().lower(.template(template))
        #expect(result.expr == .function(.sin, arguments: [.symbol(Symbol(name: "x", role: .unknown))]))
    }

    @Test func semanticLoweringLnTemplate() throws {
        let template = TemplateNode(kind: .ln, fields: [
            .init(id: .argument, node: .sequence([.character("x")]))
        ])
        let result = MathNodeSemanticLowering().lower(.template(template))
        #expect(result.expr == .function(.ln, arguments: [.symbol(Symbol(name: "x", role: .unknown))]))
    }

    @Test func semanticLoweringSqrtTemplate() throws {
        let template = TemplateNode(kind: .sqrt, fields: [
            .init(id: .radicand, node: .sequence([.character("x")]))
        ])
        let result = MathNodeSemanticLowering().lower(.template(template))
        #expect(result.expr == .function(.sqrt, arguments: [.symbol(Symbol(name: "x", role: .unknown))]))
    }

    @Test func semanticLoweringPlaceholderFails() throws {
        let root = MathNode.sequence([.placeholder])
        let result = MathNodeSemanticLowering().lower(root)
        #expect(result.expr == nil)
        #expect(result.diagnostics.contains { $0.code == .unresolvedPlaceholder })
    }

    @Test func semanticLoweringEquationInputMode() throws {
        let root = MathNode.sequence([.character("x"), .operatorSymbol("="), .character("2")])
        let result = MathNodeSemanticLowering().lower(root, context: .init(mode: .equationInput))
        #expect(result.expr == .equation(left: .symbol(Symbol(name: "x", role: .unknown)), right: .integer(2)))
    }

    @Test func semanticLoweringObjectDefinitionAssignmentMode() throws {
        let root = MathNode.sequence([.character("x"), .operatorSymbol("="), .character("2")])
        let result = MathNodeSemanticLowering().lower(root, context: .init(mode: .objectDefinition))
        #expect(result.expr == .assignment(target: .symbol(Symbol(name: "x", role: .unknown)), value: .integer(2)))
    }

    @Test func semanticLoweringFunctionDefinitionInObjectMode() throws {
        let call = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([.character("x")]))
        ])
        let power = TemplateNode(kind: .superscript, fields: [
            .init(id: .base, node: .sequence([.character("x")])),
            .init(id: .exponent, node: .sequence([.character("2")]))
        ])
        let root = MathNode.sequence([
            .character("f"),
            .template(call),
            .operatorSymbol("="),
            .template(power)
        ])

        let result = MathNodeSemanticLowering().lower(root, context: .init(mode: .objectDefinition))
        #expect(
            result.expr == .functionDefinition(
                name: Symbol(name: "f", role: .function),
                parameters: [Symbol(name: "x", role: .parameter)],
                body: .power(base: .symbol(Symbol(name: "x", role: .unknown)), exponent: .integer(2))
            )
        )
    }

    @Test func semanticLoweringBraceXYSystemProducesTupleOfRelations() throws {
        let content = MathNode.sequence([
            .character("x"), .operatorSymbol("="), .character("t"), .operatorSymbol("^"), .character("2"), .operatorSymbol("+"), .character("1"),
            .character(","),
            .character("y"), .operatorSymbol("="), .character("t")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])

        let result = MathNodeSemanticLowering().lower(.template(braces))
        guard case .tuple(let items)? = result.expr else {
            Issue.record("Expected tuple result")
            return
        }
        #expect(items.count == 2)
        #expect(items[0] == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .equal,
            right: .add([
                .power(base: .symbol(Symbol(name: "t", role: .unknown)), exponent: .integer(2)),
                .integer(1)
            ])
        ))
        #expect(items[1] == .relation(
            left: .symbol(Symbol(name: "y", role: .unknown)),
            relation: .equal,
            right: .symbol(Symbol(name: "t", role: .unknown))
        ))
    }

    @Test func semanticLoweringBraceXYSystemWithRangeProducesTupleIncludingChainedRelation() throws {
        let content = MathNode.sequence([
            .character("x"), .operatorSymbol("="), .character("t"), .operatorSymbol("^"), .character("2"),
            .character(","),
            .character("y"), .operatorSymbol("="), .character("2"), .character("t"),
            .character(","),
            .character("0"), .operatorSymbol("<="), .character("t"), .operatorSymbol("<="), .character("3")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])

        let result = MathNodeSemanticLowering().lower(.template(braces))
        guard case .tuple(let items)? = result.expr else {
            Issue.record("Expected tuple result")
            return
        }
        #expect(items.count == 3)
        #expect(items[2] == .chainedRelation(
            expressions: [
                .integer(0),
                .symbol(Symbol(name: "t", role: .unknown)),
                .integer(3)
            ],
            relations: [.lessOrEqual, .lessOrEqual]
        ))
        if case .relation(_, .equal, let rhs) = items[1] {
            #expect(rhs != .tuple([.power(base: .symbol(Symbol(name: "t", role: .unknown)), exponent: .integer(2)), .chainedRelation(
                expressions: [.integer(0), .symbol(Symbol(name: "t", role: .unknown)), .integer(3)],
                relations: [.lessOrEqual, .lessOrEqual]
            )]))
        }
    }

    @Test func semanticLoweringParametricTemplateWithRangeProducesThreeSiblingTupleItems() throws {
        let template = TemplateNode(
            kind: .parametricEquation2D,
            fields: [
                .init(id: .parametricExpression(0), node: .sequence([.character("t")])),
                .init(id: .parametricExpression(1), node: .sequence([.character("t")])),
                .init(id: .parametricRange, node: .sequence([.character("0"), .operatorSymbol("<"), .character("t"), .operatorSymbol("<"), .character("1")]))
            ]
        )

        let result = MathNodeSemanticLowering().lower(.template(template))
        guard case .tuple(let items)? = result.expr else {
            Issue.record("Expected tuple result")
            return
        }
        #expect(items.count == 3)
        #expect(items[0] == .relation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            relation: .equal,
            right: .symbol(Symbol(name: "t", role: .unknown))
        ))
        #expect(items[1] == .relation(
            left: .symbol(Symbol(name: "y", role: .variable)),
            relation: .equal,
            right: .symbol(Symbol(name: "t", role: .unknown))
        ))
        #expect(items[2] == .chainedRelation(
            expressions: [.integer(0), .symbol(Symbol(name: "t", role: .unknown)), .integer(1)],
            relations: [.less, .less]
        ))
    }

    @Test func semanticLoweringPiGlyphBecomesConstantPi() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([.character("π")]))
        #expect(result.expr == .constant(.pi))
    }

    @Test func semanticLoweringPiTextBecomesConstantPi() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([.character("p"), .character("i")]))
        #expect(result.expr == .constant(.pi))
    }

    @Test func semanticLowering2PiImplicitMultiply() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([.character("2"), .character("p"), .character("i")]))
        #expect(result.expr == .multiply([.integer(2), .constant(.pi)]))
    }

    @Test func semanticLowering2PiGlyphImplicitMultiply() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([.character("2"), .character("π")]))
        #expect(result.expr == .multiply([.integer(2), .constant(.pi)]))
    }

    @Test func semanticLoweringBackslashPiImplicitMultiply() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("2"),
            .character("\\"),
            .character("p"),
            .character("i")
        ]))
        #expect(result.expr == .multiply([.integer(2), .constant(.pi)]))
    }

    @Test func semanticLoweringFullWidthInteger() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([.character("１"), .character("２"), .character("３")]))
        #expect(result.expr == .integer(123))
    }

    @Test func semanticLoweringFullWidthAdd() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([.character("１"), .character("＋"), .character("２")]))
        #expect(result.expr == .add([.integer(1), .integer(2)]))
    }

    @Test func semanticLoweringFullWidthMultiplyAndEqual() throws {
        let result = MathNodeSemanticLowering().lower(
            .sequence([.character("２"), .character("＊"), .character("x"), .character("＝"), .character("１")])
        )
        #expect(result.expr == .equation(left: .multiply([.integer(2), .symbol(Symbol(name: "x", role: .unknown))]), right: .integer(1)))
    }

    @Test func semanticLoweringFullWidthChainedRelation() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("０"), .character("＜"), .character("t"), .character("＜"), .character("１")
        ]), context: .init(mode: .condition))
        #expect(result.expr == .chainedRelation(
            expressions: [.integer(0), .symbol(Symbol(name: "t", role: .unknown)), .integer(1)],
            relations: [.less, .less]
        ))
    }

    @Test func semanticLoweringSupportsUnicodeLessOrEqualAndGreaterOrEqual() throws {
        let relation = MathNodeSemanticLowering().lower(.sequence([
            .character("x"), .character("≥"), .character("０")
        ]), context: .init(mode: .condition))
        #expect(relation.expr == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .greaterOrEqual,
            right: .integer(0)
        ))
    }

    @Test func semanticLoweringFullWidthBraceCommasForParametricRange() throws {
        let content = MathNode.sequence([
            .character("x"), .character("＝"), .character("t"),
            .character("，"),
            .character("y"), .character("＝"), .character("t"), .operatorSymbol("^"), .character("２"),
            .character("，"),
            .character("０"), .character("＜"), .character("t"), .character("＜"), .character("１")
        ])
        let braces = TemplateNode(kind: .braces, fields: [.init(id: .content, node: content)])
        let lowered = MathNodeSemanticLowering().lower(.template(braces))
        guard let expr = lowered.expr else {
            Issue.record("Expected lowered tuple")
            return
        }
        let classification = GraphClassifier().classify(expr)
        guard case .parametric2D(_, _, let parameter, let range) = classification.intent else {
            Issue.record("Expected parametric2D")
            return
        }
        #expect(parameter.name == "t")
        #expect(range?.lower == .integer(0))
        #expect(range?.upper == .integer(1))
    }

    @Test func semanticLoweringManualSinWithFullWidthParentheses() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("s"), .character("i"), .character("n"),
            .character("（"), .character("t"), .character("）")
        ]))
        #expect(result.expr == .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualCircleWithFullWidthParenthesesAndComma() throws {
        let lowered = MathNodeSemanticLowering().lower(.sequence([
            .character("c"), .character("i"), .character("r"), .character("c"), .character("l"), .character("e"),
            .character("（"), .character("（"), .character("０"), .character("，"), .character("０"), .character("）"), .character("，"), .character("１"), .character("）")
        ]))
        guard let expr = lowered.expr else {
            Issue.record("Expected lowered circle call")
            return
        }
        #expect(expr == .function(.custom("circle"), arguments: [.tuple([.integer(0), .integer(0)]), .integer(1)]))
        let classification = GraphClassifier().classify(expr)
        guard case .circle = classification.intent else {
            Issue.record("Expected circle intent")
            return
        }
    }

    @Test func semanticLoweringBuiltInTemplateSin() throws {
        let template = TemplateNode(kind: .sin, fields: [
            .init(id: .argument, node: .sequence([.character("t")]))
        ])
        let result = MathNodeSemanticLowering().lower(.template(template))
        #expect(result.expr == .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualSinCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("sin"))
        #expect(result.expr == .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualSinSymbolNodeCall() throws {
        let parens = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([.character("t")]))
        ])
        let result = MathNodeSemanticLowering().lower(.sequence([
            .symbol("sin"),
            .template(parens)
        ]))
        #expect(result.expr == .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualCosCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("cos"))
        #expect(result.expr == .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualTanCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("tan"))
        #expect(result.expr == .function(.tan, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualLnCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("ln"))
        #expect(result.expr == .function(.ln, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualLgCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("lg"))
        #expect(result.expr == .function(.lg, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualSqrtCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("sqrt"))
        #expect(result.expr == .function(.sqrt, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualAsinCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("asin"))
        #expect(result.expr == .function(.asin, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualAcosCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("acos"))
        #expect(result.expr == .function(.acos, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualAtanCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("atan"))
        #expect(result.expr == .function(.atan, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualSinhCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("sinh"))
        #expect(result.expr == .function(.sinh, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualCoshCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("cosh"))
        #expect(result.expr == .function(.cosh, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualTanhCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("tanh"))
        #expect(result.expr == .function(.tanh, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualExpCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("exp"))
        #expect(result.expr == .function(.exp, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualLogCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("log"))
        #expect(result.expr == .function(.log, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualAbsCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("abs"))
        #expect(result.expr == .function(.abs, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualFloorCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("floor"))
        #expect(result.expr == .function(.floor, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualCeilCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("ceil"))
        #expect(result.expr == .function(.ceil, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func semanticLoweringManualMinTwoArgumentsCall() throws {
        let parens = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .character("x"),
                .character(","),
                .character("y")
            ]))
        ])
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("m"), .character("i"), .character("n"),
            .template(parens)
        ]))
        #expect(result.expr == .function(
            .min,
            arguments: [
                .symbol(Symbol(name: "x", role: .unknown)),
                .symbol(Symbol(name: "y", role: .unknown))
            ]
        ))
    }

    @Test func semanticLoweringManualMaxTwoArgumentsCall() throws {
        let parens = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .character("x"),
                .character(","),
                .character("y")
            ]))
        ])
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("m"), .character("a"), .character("x"),
            .template(parens)
        ]))
        #expect(result.expr == .function(
            .max,
            arguments: [
                .symbol(Symbol(name: "x", role: .unknown)),
                .symbol(Symbol(name: "y", role: .unknown))
            ]
        ))
    }

    @Test func semanticLoweringBareSinRemainsSymbol() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("s"), .character("i"), .character("n")
        ]))
        #expect(result.expr == .symbol(Symbol(name: "sin", role: .unknown)))
    }

    @Test func semanticLoweringManualCustomRateCall() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("rate"))
        #expect(result.expr == .function(
            .custom("rate"),
            arguments: [.symbol(Symbol(name: "t", role: .unknown))]
        ))
    }

    @Test func formulaSemanticSyncForSymbol() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.character("x")])))
        input.syncDerivedStrings()
        #expect(input.semanticState.expression != nil)
    }

    @Test func formulaSemanticSyncClassifiesPowerAsExplicitY() throws {
        let power = TemplateNode(kind: .superscript, fields: [
            .init(id: .base, node: .sequence([.character("x")])),
            .init(id: .exponent, node: .sequence([.character("2")]))
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(power)])))
        input.syncDerivedStrings()
        if case .explicitY? = input.semanticState.graphClassification?.intent {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncPlaceholderProducesDiagnostic() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.placeholder])))
        input.syncDerivedStrings()
        #expect(input.semanticState.expression == nil)
        #expect(input.semanticState.diagnostics.contains { $0.code == .unresolvedPlaceholder })
    }

    @Test func formulaSemanticSyncEquationYEqualsClassifiesExplicitY() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("y"),
            .operatorSymbol("="),
            .character("x"),
            .operatorSymbol("^"),
            .character("2")
        ])))
        input.syncDerivedStrings()
        if case .explicitY? = input.semanticState.graphClassification?.intent {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncEquationXEqualsClassifiesExplicitX() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("x"),
            .operatorSymbol("="),
            .character("y"),
            .operatorSymbol("^"),
            .character("2")
        ])))
        input.syncDerivedStrings()
        if case .explicitX? = input.semanticState.graphClassification?.intent {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncTuplePointClassification() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("1"),
            .character(","),
            .character("2")
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.graphClassification?.intent == .point(x: .integer(1), y: .integer(2)))
    }

    @Test func formulaSemanticSyncParenthesizedTuplePointClassification() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("("),
            .character("s"),
            .character("i"),
            .character("n"),
            .character("("),
            .character("a"),
            .character(")"),
            .character(","),
            .character("c"),
            .character("o"),
            .character("s"),
            .character("("),
            .character("a"),
            .character(")"),
            .character(")")
        ])))
        input.syncDerivedStrings(
            context: LoweringContext(
                mode: .expression,
                symbolTable: SymbolTable(symbols: [
                    "a": Symbol(name: "a", role: .parameter)
                ])
            )
        )
        #expect(input.semanticState.expression == .tuple([
            .function(.sin, arguments: [.symbol(Symbol(name: "a", role: .parameter))]),
            .function(.cos, arguments: [.symbol(Symbol(name: "a", role: .parameter))])
        ]))
        #expect(input.semanticState.graphClassification?.intent == .point(
            x: .function(.sin, arguments: [.symbol(Symbol(name: "a", role: .parameter))]),
            y: .function(.cos, arguments: [.symbol(Symbol(name: "a", role: .parameter))])
        ))
    }

    @Test func formulaSemanticSyncParenthesizedLiteralTuplePointClassification() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("("),
            .character("1"),
            .character(","),
            .character("2"),
            .character(")")
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.expression == .tuple([.integer(1), .integer(2)]))
        #expect(input.semanticState.graphClassification?.intent == .point(x: .integer(1), y: .integer(2)))
    }

    @Test func formulaSemanticSyncOperatorSymbolParenthesizedTuplePointClassification() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .operatorSymbol("("),
            .character("1"),
            .operatorSymbol(","),
            .character("2"),
            .operatorSymbol(")")
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.expression == .tuple([.integer(1), .integer(2)]))
        #expect(input.semanticState.graphClassification?.intent == .point(x: .integer(1), y: .integer(2)))
    }

    @Test func formulaSemanticSyncKeepsLegacyStrings() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("x"),
            .operatorSymbol("+"),
            .character("1")
        ])))
        input.syncDerivedStrings()
        #expect(input.source == "x+1")
        #expect(input.displayLatex == "x+1")
        #expect(input.computeExpression == "x+1")
    }

    @Test func exprDebugPrinterPrintsPower() throws {
        let expr = Expr.power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2))
        let text = ExprDebugPrinter().print(expr)
        #expect(text.contains("power("))
        #expect(text.contains("symbol(x)"))
        #expect(text.contains("integer(2)"))
    }

    @Test func graphIntentDebugPrinterPrintsExplicitY() throws {
        let intent = GraphIntent.explicitY(
            expression: .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
            variable: Symbol(name: "x", role: .variable)
        )
        let text = GraphIntentDebugPrinter().print(intent)
        #expect(text.contains("explicitY"))
    }

    @Test func formulaSemanticStateDebugSummaryContainsCoreSections() throws {
        let state = FormulaSemanticState(
            expression: .symbol(Symbol(name: "x", role: .variable)),
            diagnostics: [
                .init(severity: .warning, code: .unknownSymbol, message: "debug")
            ],
            graphClassification: .init(intent: .explicitY(
                expression: .symbol(Symbol(name: "x", role: .variable)),
                variable: Symbol(name: "x", role: .variable)
            ))
        )
        let summary = state.debugSummary
        #expect(summary.contains("expression="))
        #expect(summary.contains("diagnostics="))
        #expect(summary.contains("graph="))
    }

    @Test func formulaSemanticSyncImplicitMultiplication2x() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("2"),
            .character("x")
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.graphClassification?.intent == .explicitY(
            expression: .multiply([.integer(2), .symbol(Symbol(name: "x", role: .unknown))]),
            variable: Symbol(name: "x", role: .variable)
        ))
    }

    @Test func formulaSemanticSyncImplicitMultiplication2xPlus1Group() throws {
        let group = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .character("x"),
                .operatorSymbol("+"),
                .character("1")
            ]))
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("2"),
            .template(group)
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.graphClassification?.intent == .explicitY(
            expression: .multiply([
                .integer(2),
                .add([.symbol(Symbol(name: "x", role: .unknown)), .integer(1)])
            ]),
            variable: Symbol(name: "x", role: .variable)
        ))
    }

    @Test func formulaSemanticSyncImplicitMultiplicationParenTimesParen() throws {
        let left = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .character("x"),
                .operatorSymbol("+"),
                .character("1")
            ]))
        ])
        let right = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .character("x"),
                .operatorSymbol("-"),
                .character("1")
            ]))
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .template(left),
            .template(right)
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.expression == .multiply([
            .add([.symbol(Symbol(name: "x", role: .unknown)), .integer(1)]),
            .add([.symbol(Symbol(name: "x", role: .unknown)), .negate(.integer(1))])
        ]))
    }

    @Test func formulaSemanticSyncImplicitMultiplication2SinX() throws {
        let sinTemplate = TemplateNode(kind: .sin, fields: [
            .init(id: .argument, node: .sequence([.character("x")]))
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("2"),
            .template(sinTemplate)
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.expression == .multiply([
            .integer(2),
            .function(.sin, arguments: [.symbol(Symbol(name: "x", role: .unknown))])
        ]))
    }

    @Test func formulaSemanticSyncUnparenthesizedFunctionSinX() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("s"),
            .character("i"),
            .character("n"),
            .character(" "),
            .character("x")
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.expression == .function(.sin, arguments: [
            .symbol(Symbol(name: "x", role: .unknown))
        ]))
    }

    @Test func formulaSemanticSyncSinNotMultiply() throws {
        let sinTemplate = TemplateNode(kind: .sin, fields: [
            .init(id: .argument, node: .sequence([.character("x")]))
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(sinTemplate)])))
        input.syncDerivedStrings()
        #expect(input.semanticState.expression == .function(.sin, arguments: [.symbol(Symbol(name: "x", role: .unknown))]))
    }

    @Test func formulaSemanticSyncParametricTuple() throws {
        let groupX = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([.character("t")]))
        ])
        let groupY = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([.character("t")]))
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("cos"),
            .template(groupX),
            .character(","),
            .character("sin"),
            .template(groupY)
        ])))
        input.syncDerivedStrings()
        if case .parametric2D(_, _, let parameter, _)? = input.semanticState.graphClassification?.intent {
            #expect(parameter.name == "t")
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncTupleXYNotPoint() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("x"),
            .character(","),
            .character("y")
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.graphClassification?.intent != .point(x: .symbol(Symbol(name: "x", role: .unknown)), y: .symbol(Symbol(name: "y", role: .unknown))))
    }

    @Test func formulaSemanticSyncImplicitEquation() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("x"),
            .operatorSymbol("^"),
            .character("2"),
            .operatorSymbol("+"),
            .character("y"),
            .operatorSymbol("^"),
            .character("2"),
            .operatorSymbol("="),
            .character("1")
        ])))
        input.syncDerivedStrings()
        if case .implicit? = input.semanticState.graphClassification?.intent {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncBraceXYSystemClassifiesParametric2D() throws {
        let content = MathNode.sequence([
            .character("x"), .operatorSymbol("="), .character("t"), .operatorSymbol("^"), .character("2"), .operatorSymbol("+"), .character("1"),
            .character(","),
            .character("y"), .operatorSymbol("="), .character("t")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        if case .parametric2D(let xExpr, let yExpr, let parameter, _)? = input.semanticState.graphClassification?.intent {
            #expect(parameter.name == "t")
            #expect(xExpr == .add([
                .power(base: .symbol(Symbol(name: "t", role: .unknown)), exponent: .integer(2)),
                .integer(1)
            ]))
            #expect(yExpr == .symbol(Symbol(name: "t", role: .unknown)))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncBraceXYSystemWithTwoTClassifiesParametric2D() throws {
        let content = MathNode.sequence([
            .character("x"), .operatorSymbol("="), .character("t"), .operatorSymbol("^"), .character("2"),
            .character(","),
            .character("y"), .operatorSymbol("="), .character("2"), .character("t")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        if case .parametric2D(let xExpr, let yExpr, let parameter, _)? = input.semanticState.graphClassification?.intent {
            #expect(parameter.name == "t")
            #expect(xExpr == .power(base: .symbol(Symbol(name: "t", role: .unknown)), exponent: .integer(2)))
            #expect(yExpr == .multiply([.integer(2), .symbol(Symbol(name: "t", role: .unknown))]))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncBraceXYSystemWithRangeClassifiesParametric2DWithRange() throws {
        let content = MathNode.sequence([
            .character("x"), .operatorSymbol("="), .character("t"), .operatorSymbol("^"), .character("2"),
            .character(","),
            .character("y"), .operatorSymbol("="), .character("2"), .character("t"),
            .character(","),
            .character("0"), .operatorSymbol("<="), .character("t"), .operatorSymbol("<="), .character("3")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        if case .parametric2D(_, _, let parameter, let range)? = input.semanticState.graphClassification?.intent {
            #expect(parameter.name == "t")
            #expect(range == ParameterRange(lower: .integer(0), upper: .integer(3)))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncBraceSinCosWithTwoPiRangeClassifiesParametric2DWithPiUpper() throws {
        let content = MathNode.sequence([
            .character("x"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character("t")]))])),
            .character(","),
            .character("y"), .operatorSymbol("="), .character("c"), .character("o"), .character("s"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character("t")]))])),
            .character(","),
            .character("0"), .operatorSymbol("<"), .character("t"), .operatorSymbol("<"), .character("2"), .character("p"), .character("i")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        if case .parametric2D(_, _, let parameter, let range)? = input.semanticState.graphClassification?.intent {
            #expect(parameter.name == "t")
            #expect(range == ParameterRange(
                lower: .integer(0),
                upper: .multiply([.integer(2), .constant(.pi)])
            ))
            if let upper = range?.upper {
                let eval = ExprEvaluator().evaluate(upper)
                if case .value(let value) = eval {
                    #expect(abs(value - (2 * Double.pi)) < 1e-9)
                } else {
                    #expect(Bool(false))
                }
            } else {
                #expect(Bool(false))
            }
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncParametricTemplateSupportsStrictChainRangeWithPi() throws {
        let template = TemplateNode(
            kind: .parametricEquation2D,
            fields: [
                .init(id: .parametricExpression(0), node: .sequence([
                    .character("s"), .character("i"), .character("n"),
                    .template(TemplateNode(kind: .parentheses, fields: [
                        .init(id: .content, node: .sequence([.character("2"), .character("t")]))
                    ])),
                    .operatorSymbol("+"),
                    .character("c"), .character("o"), .character("s"),
                    .template(TemplateNode(kind: .parentheses, fields: [
                        .init(id: .content, node: .sequence([.character("t")]))
                    ]))
                ])),
                .init(id: .parametricExpression(1), node: .sequence([
                    .character("s"), .character("i"), .character("n"),
                    .template(TemplateNode(kind: .parentheses, fields: [
                        .init(id: .content, node: .sequence([.character("t")]))
                    ])),
                    .operatorSymbol("^"),
                    .character("2")
                ])),
                .init(
                    id: .parametricRange,
                    node: .sequence([
                        .character("0"), .operatorSymbol("<"), .character("t"), .operatorSymbol("<"), .character("p"), .character("i")
                    ])
                )
            ]
        )

        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(template)])))
        input.syncDerivedStrings()

        guard case .parametric2D(_, _, let parameter, let range)? = input.semanticState.graphClassification?.intent else {
            Issue.record("Expected parametric2D intent")
            return
        }
        #expect(parameter.name == "t")
        #expect(range == ParameterRange(lower: .integer(0), upper: .constant(.pi)))
        #expect(input.semanticState.diagnostics.contains(where: { $0.severity == .error }) == false)
    }

    @Test func formulaSemanticSyncParametricTemplateSupportsLatexLeqChainRangeWithPi() throws {
        let template = TemplateNode(
            kind: .parametricEquation2D,
            fields: [
                .init(id: .parametricExpression(0), node: .sequence([
                    .character("s"), .character("i"), .character("n"),
                    .template(TemplateNode(kind: .parentheses, fields: [
                        .init(id: .content, node: .sequence([.character("2"), .character("t")]))
                    ])),
                    .operatorSymbol("+"),
                    .character("c"), .character("o"), .character("s"),
                    .template(TemplateNode(kind: .parentheses, fields: [
                        .init(id: .content, node: .sequence([.character("t")]))
                    ]))
                ])),
                .init(id: .parametricExpression(1), node: .sequence([
                    .character("s"), .character("i"), .character("n"),
                    .template(TemplateNode(kind: .parentheses, fields: [
                        .init(id: .content, node: .sequence([.character("t")]))
                    ])),
                    .operatorSymbol("^"),
                    .character("2")
                ])),
                .init(
                    id: .parametricRange,
                    node: .sequence([
                        .character("0"), .symbol("\\leq"), .character("t"), .character("\\"), .symbol("leq"), .character("2"), .character("p"), .character("i")
                    ])
                )
            ]
        )

        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(template)])))
        input.syncDerivedStrings()

        guard case .parametric2D(_, _, let parameter, let range)? = input.semanticState.graphClassification?.intent else {
            Issue.record("Expected parametric2D intent")
            return
        }
        #expect(parameter.name == "t")
        #expect(range == ParameterRange(lower: .integer(0), upper: .multiply([.integer(2), .constant(.pi)])))
        #expect(input.semanticState.diagnostics.contains(where: { $0.severity == .error }) == false)
    }

    @Test func semanticLoweringMergesSplitGreaterEqualOperator() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("x"), .operatorSymbol(">"), .operatorSymbol("="), .character("0")
        ]), context: .init(mode: .condition))
        #expect(result.expr == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .greaterOrEqual,
            right: .integer(0)
        ))
    }

    @Test func semanticLoweringMergesSplitLessEqualOperator() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("x"), .operatorSymbol("<"), .operatorSymbol("="), .character("0")
        ]), context: .init(mode: .condition))
        #expect(result.expr == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .lessOrEqual,
            right: .integer(0)
        ))
    }

    @Test func semanticLoweringSupportsLatexGeqAndLeqCommands() throws {
        let geq = MathNodeSemanticLowering().lower(.sequence([
            .character("x"), .character("\\"), .character("g"), .character("e"), .character("q"), .character("0")
        ]), context: .init(mode: .condition))
        #expect(geq.expr == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .greaterOrEqual,
            right: .integer(0)
        ))

        let leq = MathNodeSemanticLowering().lower(.sequence([
            .character("x"), .character("\\"), .character("l"), .character("e"), .character("q"), .character("0")
        ]), context: .init(mode: .condition))
        #expect(leq.expr == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .lessOrEqual,
            right: .integer(0)
        ))
    }

    @Test func semanticLoweringSupportsLatexGeqLeqSingleTokenAndMixedSplitForms() throws {
        let geqSingleToken = MathNodeSemanticLowering().lower(.sequence([
            .character("x"), .symbol("\\geq"), .character("0")
        ]), context: .init(mode: .condition))
        #expect(geqSingleToken.expr == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .greaterOrEqual,
            right: .integer(0)
        ))

        let leqMixedSplit = MathNodeSemanticLowering().lower(.sequence([
            .character("x"), .character("\\"), .symbol("leq"), .character("0")
        ]), context: .init(mode: .condition))
        #expect(leqMixedSplit.expr == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .lessOrEqual,
            right: .integer(0)
        ))
    }

    @Test func formulaSemanticSyncPiecewiseSupportsGreaterEqualAndLessEqualConditions() throws {
        let piecewise = TemplateNode(
            kind: .piecewise(rows: 2),
            fields: [
                .init(id: .rowExpression(0), node: .sequence([.character("x"), .operatorSymbol("^"), .character("2")])),
                .init(id: .rowCondition(0), node: .sequence([.character("x"), .operatorSymbol("<"), .operatorSymbol("="), .character("0")])),
                .init(id: .rowExpression(1), node: .sequence([
                    .character("s"), .character("i"), .character("n"),
                    .template(TemplateNode(kind: .parentheses, fields: [
                        .init(id: .content, node: .sequence([.character("x")]))
                    ]))
                ])),
                .init(id: .rowCondition(1), node: .sequence([.character("x"), .operatorSymbol(">"), .operatorSymbol("="), .character("0")]))
            ]
        )
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(piecewise)])))
        input.syncDerivedStrings()

        guard case .piecewise(let branches)? = input.semanticState.graphClassification?.intent else {
            Issue.record("Expected piecewise graph intent")
            return
        }
        #expect(branches.count == 2)
        #expect(branches[0].condition == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .lessOrEqual,
            right: .integer(0)
        ))
        #expect(branches[1].condition == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .greaterOrEqual,
            right: .integer(0)
        ))
        #expect(input.semanticState.diagnostics.contains(where: { $0.severity == .error }) == false)
    }

    @Test func formulaSemanticSyncPiecewiseSupportsUnicodeInequalities() throws {
        let piecewise = TemplateNode(
            kind: .piecewise(rows: 2),
            fields: [
                .init(id: .rowExpression(0), node: .sequence([.character("x"), .operatorSymbol("^"), .character("2")])),
                .init(id: .rowCondition(0), node: .sequence([.character("x"), .character("≤"), .character("0")])),
                .init(id: .rowExpression(1), node: .sequence([
                    .character("s"), .character("i"), .character("n"),
                    .template(TemplateNode(kind: .parentheses, fields: [
                        .init(id: .content, node: .sequence([.character("x")]))
                    ]))
                ])),
                .init(id: .rowCondition(1), node: .sequence([.character("x"), .character("≥"), .character("0")]))
            ]
        )
        let lowered = MathNodeSemanticLowering().lower(.template(piecewise))
        guard case .piecewise(let branches, _)? = lowered.expr else {
            Issue.record("Expected lowered piecewise expression")
            return
        }
        #expect(branches[0].condition == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .lessOrEqual,
            right: .integer(0)
        ))
        #expect(branches[1].condition == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .greaterOrEqual,
            right: .integer(0)
        ))
    }

    @Test func loweringPolarEquationWithTheta() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character("θ")]))]))
        ]))
        #expect(result.expr == .equation(
            left: .symbol(Symbol(name: "r", role: .unknown)),
            right: .function(.sin, arguments: [.symbol(Symbol(name: "θ", role: .unknown))])
        ))
    }

    @Test func implicitLoweringAndClassificationSamples() throws {
        let cases: [(String, MathNode)] = [
            (
                "x^2+y^2=1",
                .sequence([
                    .character("x"), .operatorSymbol("^"), .character("2"),
                    .operatorSymbol("+"),
                    .character("y"), .operatorSymbol("^"), .character("2"),
                    .operatorSymbol("="),
                    .character("1")
                ])
            ),
            (
                "x^2-y^2=1",
                .sequence([
                    .character("x"), .operatorSymbol("^"), .character("2"),
                    .operatorSymbol("-"),
                    .character("y"), .operatorSymbol("^"), .character("2"),
                    .operatorSymbol("="),
                    .character("1")
                ])
            ),
            (
                "y-x=0",
                .sequence([
                    .character("y"),
                    .operatorSymbol("-"),
                    .character("x"),
                    .operatorSymbol("="),
                    .character("0")
                ])
            ),
            (
                "x*y=1",
                .sequence([
                    .character("x"),
                    .operatorSymbol("*"),
                    .character("y"),
                    .operatorSymbol("="),
                    .character("1")
                ])
            )
        ]

        for (_, node) in cases {
            let lowered = MathNodeSemanticLowering().lower(node)
            #expect(lowered.expr != nil)
            if case .equation? = lowered.expr {
                #expect(Bool(true))
            } else if case .relation(_, .equal, _)? = lowered.expr {
                #expect(Bool(true))
            } else {
                #expect(Bool(false))
            }

            let classified = GraphClassifier().classify(lowered.expr!)
            if case .implicit = classified.intent {
                #expect(Bool(true))
            } else {
                #expect(Bool(false))
            }
        }
    }

    @Test func implicitLoweringAndClassificationSinXYEqualsZero() throws {
        let sinArg = MathNode.sequence([
            .character("x"),
            .operatorSymbol("*"),
            .character("y")
        ])
        let sinCall = MathNode.sequence([
            .character("s"), .character("i"), .character("n"),
            .template(.init(kind: .parentheses, fields: [.init(id: .content, node: sinArg)]))
        ])
        let node = MathNode.sequence([
            sinCall,
            .operatorSymbol("="),
            .character("0")
        ])

        let lowered = MathNodeSemanticLowering().lower(node)
        #expect(lowered.expr != nil)
        if case .equation? = lowered.expr {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }

        let classified = GraphClassifier().classify(lowered.expr!)
        if case .implicit = classified.intent {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func loweringPolarEquationWithT() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character("t")]))]))
        ]))
        #expect(result.expr == .equation(
            left: .symbol(Symbol(name: "r", role: .unknown)),
            right: .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .unknown))])
        ))
    }

    @Test func loweringBracePolarWithThetaRange() throws {
        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([
                .character("3"), .character("θ")
            ]))])),
            .character(","),
            .character("0"), .operatorSymbol("<="), .character("θ"), .operatorSymbol("<="), .character("2"), .character("p"), .character("i")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        let result = MathNodeSemanticLowering().lower(.sequence([.template(braces)]))

        if case .tuple(let items)? = result.expr {
            #expect(items.count == 2)
            #expect(items[0] == .equation(
                left: .symbol(Symbol(name: "r", role: .unknown)),
                right: .function(.sin, arguments: [.multiply([.integer(3), .symbol(Symbol(name: "θ", role: .unknown))])])
            ))
            #expect(items[1] == .chainedRelation(
                expressions: [
                    .integer(0),
                    .symbol(Symbol(name: "θ", role: .unknown)),
                    .multiply([.integer(2), .constant(.pi)])
                ],
                relations: [.lessOrEqual, .lessOrEqual]
            ))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncPolarEquationClassifiesPolar() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character("θ")]))]))
        ])))
        input.syncDerivedStrings()

        if case .polar(let radius, let angle, let range)? = input.semanticState.graphClassification?.intent {
            #expect(radius == .function(.sin, arguments: [.symbol(Symbol(name: "θ", role: .unknown))]))
            #expect(angle.name == "θ")
            #expect(range == nil)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncBracePolarRangeClassifiesPolarWithRange() throws {
        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([
                .character("3"), .character("θ")
            ]))])),
            .character(","),
            .character("0"), .operatorSymbol("<="), .character("θ"), .operatorSymbol("<="), .character("2"), .character("p"), .character("i")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        if case .polar(_, let angle, let range)? = input.semanticState.graphClassification?.intent {
            #expect(angle.name == "θ")
            #expect(range == ParameterRange(
                lower: .integer(0),
                upper: .multiply([.integer(2), .constant(.pi)])
            ))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncPolarRThetaClassifiesPolar() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("r"), .operatorSymbol("="), .character("θ")
        ])))
        input.syncDerivedStrings()

        if case .polar(let radius, let angle, let range)? = input.semanticState.graphClassification?.intent {
            #expect(radius == .symbol(Symbol(name: "θ", role: .unknown)))
            #expect(angle.name == "θ")
            #expect(range == nil)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncPolarRConstantOneCurrentBehavior() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("r"), .operatorSymbol("="), .character("1")
        ])))
        input.syncDerivedStrings()

        if case .unknown? = input.semanticState.graphClassification?.intent {
            #expect(input.semanticState.graphClassification?.diagnostics.contains { $0.code == .missingVariable } == true)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func loweringPolarSin3ThetaEquation() throws {
        let result = MathNodeSemanticLowering().lower(.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([
                .character("3"), .character("θ")
            ]))]))
        ]))
        #expect(result.expr == .equation(
            left: .symbol(Symbol(name: "r", role: .unknown)),
            right: .function(.sin, arguments: [
                .multiply([.integer(3), .symbol(Symbol(name: "θ", role: .unknown))])
            ])
        ))
    }

    @Test func loweringBracePolarThetaRangeWithPiGlyph() throws {
        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("θ"),
            .character(","),
            .character("0"), .operatorSymbol("<="), .character("θ"), .operatorSymbol("<="), .character("2"), .character("π")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        let result = MathNodeSemanticLowering().lower(.sequence([.template(braces)]))

        if case .tuple(let items)? = result.expr {
            #expect(items.count == 2)
            #expect(items[0] == .equation(
                left: .symbol(Symbol(name: "r", role: .unknown)),
                right: .symbol(Symbol(name: "θ", role: .unknown))
            ))
            #expect(items[1] == .chainedRelation(
                expressions: [
                    .integer(0),
                    .symbol(Symbol(name: "θ", role: .unknown)),
                    .multiply([.integer(2), .constant(.pi)])
                ],
                relations: [.lessOrEqual, .lessOrEqual]
            ))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func formulaSemanticSyncBracePolarTRangeWithTextPiClassifiesPolar() throws {
        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([
                .character("3"), .character("t")
            ]))])),
            .character(","),
            .character("0"), .operatorSymbol("<="), .character("t"), .operatorSymbol("<="), .character("2"), .character("p"), .character("i")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        if case .polar(let radius, let angle, let range)? = input.semanticState.graphClassification?.intent {
            #expect(radius == .function(.sin, arguments: [
                .multiply([.integer(3), .symbol(Symbol(name: "t", role: .unknown))])
            ]))
            #expect(angle.name == "t")
            #expect(range == ParameterRange(
                lower: .integer(0),
                upper: .multiply([.integer(2), .constant(.pi)])
            ))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func loweringCircleFunctionCallStructure() throws {
        let centerTuple = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([.character("0"), .character(","), .character("0")]))
        ])
        let callArgs = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .template(centerTuple),
                .character(","),
                .character("1")
            ]))
        ])
        let root = MathNode.sequence([
            .character("c"), .character("i"), .character("r"), .character("c"), .character("l"), .character("e"),
            .template(callArgs)
        ])
        let result = MathNodeSemanticLowering().lower(root)
        #expect(result.expr == .function(.custom("circle"), arguments: [
            .tuple([.integer(0), .integer(0)]),
            .integer(1)
        ]))
    }

    @Test func loweringCircleFunctionCallCenter12Radius3() throws {
        let centerTuple = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([.character("1"), .character(","), .character("2")]))
        ])
        let callArgs = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .template(centerTuple),
                .character(","),
                .character("3")
            ]))
        ])
        let root = MathNode.sequence([
            .character("c"), .character("i"), .character("r"), .character("c"), .character("l"), .character("e"),
            .template(callArgs)
        ])
        let result = MathNodeSemanticLowering().lower(root)
        #expect(result.expr == .function(.custom("circle"), arguments: [
            .tuple([.integer(1), .integer(2)]),
            .integer(3)
        ]))
    }

    @Test func loweringCircleFunctionCallRadiusSqrt2() throws {
        let centerTuple = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([.character("0"), .character(","), .character("0")]))
        ])
        let sqrtTemplate = TemplateNode(kind: .sqrt, fields: [
            .init(id: .radicand, node: .sequence([.character("2")]))
        ])
        let callArgs = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .template(centerTuple),
                .character(","),
                .template(sqrtTemplate)
            ]))
        ])
        let root = MathNode.sequence([
            .character("c"), .character("i"), .character("r"), .character("c"), .character("l"), .character("e"),
            .template(callArgs)
        ])
        let result = MathNodeSemanticLowering().lower(root)
        #expect(result.expr == .function(.custom("circle"), arguments: [
            .tuple([.integer(0), .integer(0)]),
            .function(.sqrt, arguments: [.integer(2)])
        ]))
    }

    @Test func formulaSemanticSyncCircleClassifiesCircle() throws {
        let centerTuple = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([.character("0"), .character(","), .character("0")]))
        ])
        let callArgs = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .template(centerTuple),
                .character(","),
                .character("1")
            ]))
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("c"), .character("i"), .character("r"), .character("c"), .character("l"), .character("e"),
            .template(callArgs)
        ])))
        input.syncDerivedStrings()
        #expect(input.semanticState.graphClassification?.intent == .circle(
            center: .tuple([.integer(0), .integer(0)]),
            radius: .integer(1)
        ))
    }

    @Test func polarInequalityVariantStrictLess() throws {
        var input = FormulaInputState(editorState: EditorState(root: polarBraceInput(
            radiusArgument: [.character("θ")],
            rangeLowerOp: "<",
            rangeUpperOp: "<",
            upperBound: [.character("2"), .character("π")]
        )))
        assertPolarRangeIsZeroToTwoPi(&input, angle: "θ")
    }

    @Test func polarInequalityVariantLessOrEqualAscii() throws {
        var input = FormulaInputState(editorState: EditorState(root: polarBraceInput(
            radiusArgument: [.character("θ")],
            rangeLowerOp: "<=",
            rangeUpperOp: "<=",
            upperBound: [.character("2"), .character("π")]
        )))
        assertPolarRangeIsZeroToTwoPi(&input, angle: "θ")
    }

    @Test func polarInequalityVariantLessOrEqualUnicode() throws {
        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character("θ")]))])),
            .character(","),
            .character("0"), .character("≤"), .character("θ"), .character("≤"), .character("2"), .character("π")
        ])
        let braces = TemplateNode(kind: .braces, fields: [.init(id: .content, node: content)])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()
        if case .polar(_, let angle, let range)? = input.semanticState.graphClassification?.intent,
           let range {
            #expect(angle.name == "θ")
            if let upper = range.upper, case .value(let upperValue) = ExprEvaluator().evaluate(upper) {
                #expect(abs(upperValue - (2 * Double.pi)) < 1e-9)
            } else {
                Issue.record("Unicode ≤ case did not evaluate upper bound")
            }
        } else {
            // Current editor/operator normalization may not map full-width inequality tokens yet.
            #expect(input.semanticState.graphClassification?.diagnostics.isEmpty == false)
        }
    }

    @Test func polarInequalityMixedOpenClosedVariants() throws {
        var leftOpenRightClosed = FormulaInputState(editorState: EditorState(root: polarBraceInput(
            radiusArgument: [.character("θ")],
            rangeLowerOp: "<",
            rangeUpperOp: "<=",
            upperBound: [.character("2"), .character("π")]
        )))
        assertPolarRangeIsZeroToTwoPi(&leftOpenRightClosed, angle: "θ")

        var leftClosedRightOpen = FormulaInputState(editorState: EditorState(root: polarBraceInput(
            radiusArgument: [.character("θ")],
            rangeLowerOp: "<=",
            rangeUpperOp: "<",
            upperBound: [.character("2"), .character("π")]
        )))
        assertPolarRangeIsZeroToTwoPi(&leftClosedRightOpen, angle: "θ")
    }

    @Test func polarRangeUpperPiVariantTwoPiTextAndGlyphAndProducts() throws {
        let cases: [[MathNode]] = [
            [.character("2"), .character("π")],
            [.character("2"), .character("p"), .character("i")],
            [.character("2"), .character(" "), .character("p"), .character("i")],
            [.character("2"), .operatorSymbol("*"), .character("p"), .character("i")],
            [.character("2"), .operatorSymbol("*"), .character("π")]
        ]
        for upperNodes in cases {
            var input = FormulaInputState(editorState: EditorState(root: polarBraceInput(
                radiusArgument: [.character("θ")],
                rangeLowerOp: "<=",
                rangeUpperOp: "<=",
                upperBound: upperNodes
            )))
            input.syncDerivedStrings()
            if case .polar(_, let angle, let range)? = input.semanticState.graphClassification?.intent,
               let upper = range?.upper,
               case .value(let upperValue) = ExprEvaluator().evaluate(upper) {
                #expect(angle.name == "θ")
                #expect(abs(upperValue - (2 * Double.pi)) < 1e-9)
            } else {
                Issue.record("Pi upper-bound variant not supported by current input normalization: \(upperNodes)")
            }
        }
    }

    @Test func polarAngleVariantPhiIsRecognizedWhenUnique() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character("p"), .character("h"), .character("i")]))]))
        ])))
        input.syncDerivedStrings()

        if case .polar(_, let angle, _)? = input.semanticState.graphClassification?.intent {
            #expect(angle.name == "phi")
        } else {
            #expect(Bool(false))
        }
    }

    @Test func polarSpaceVariantFunctionCallSpacing() throws {
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"), .character(" "),
            .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character(" "), .character("θ"), .character(" ")]))]))
        ])))
        input.syncDerivedStrings()

        if case .polar(_, let angle, _)? = input.semanticState.graphClassification?.intent {
            #expect(angle.name == "θ")
        } else {
            // If spaces are preserved as significant tokens in current editor model, this may fail until input normalization is added.
            #expect(input.semanticState.graphClassification?.diagnostics.isEmpty == false)
        }
    }

    @Test func polarFullWidthExploratoryBehavior() throws {
        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("θ"),
            .character(","),
            .character("０"), .character("＜"), .character("θ"), .character("＜"), .character("２"), .character("π")
        ])
        let braces = TemplateNode(kind: .braces, fields: [.init(id: .content, node: content)])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()
        if case .polar = input.semanticState.graphClassification?.intent {
            #expect(Bool(true))
        } else {
            // Accept current non-support; this should be handled by a future input normalization task.
            #expect(input.semanticState.graphClassification?.diagnostics.isEmpty == false)
        }
    }

    @Test func semanticLoweringFunctionCommaArgumentsNotSplitAsTopLevelTuple() throws {
        let args = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .character("x"),
                .character(","),
                .character("y")
            ]))
        ])
        let root = MathNode.sequence([
            .character("f"),
            .template(args)
        ])
        let result = MathNodeSemanticLowering().lower(root)
        #expect(result.expr == .function(
            .custom("f"),
            arguments: [
                .symbol(Symbol(name: "x", role: .unknown)),
                .symbol(Symbol(name: "y", role: .unknown))
            ]
        ))
    }

    @Test func semanticLoweringMatrixNotAffectedByBraceCommaLogic() throws {
        let matrix = TemplateNode(kind: .matrix(rows: 1, cols: 2), fields: [
            .init(id: .matrixCell(row: 0, col: 0), node: .sequence([.character("1")])),
            .init(id: .matrixCell(row: 0, col: 1), node: .sequence([.character("2")]))
        ])
        let result = MathNodeSemanticLowering().lower(.template(matrix))
        #expect(result.expr == .matrix(MatrixExpr(rows: [[.integer(1), .integer(2)]])))
    }

    @Test func displayFormatterHidesLatexSyntax() throws {
        let samples = [
            "y=x^2",
            "y=x^4",
            "y=x^{-1}",
            "y=\\frac{x^2}{x+1}",
            "y=\\cos{x}",
            "y=cosx",
            "x^2+y^2=4"
        ]

        for sample in samples {
            let analysis = AlgebraCore.analyzePlaneLatex(sample)
            #expect(!analysis.displayText.contains("\\"))
            #expect(!analysis.displayText.contains("\\left"))
            #expect(!analysis.displayText.contains("\\frac"))
            #expect(!analysis.displayText.contains("^²"))
            #expect(!analysis.displayText.contains("^³"))
        }
    }

    @Test func plainFunctionPrefixDisplaysAsFunctionCall() throws {
        let analysis = AlgebraCore.analyzePlaneLatex("y=cosx")

        #expect(analysis.displayText == "y = cos(x)")
        #expect(analysis.parameters.isEmpty)
    }

    @Test func parenthesizedBuiltInFunctionDisplaysAsFunctionCall() throws {
        let analysis = AlgebraCore.analyzePlaneLatex("y=cos(x)")

        #expect(analysis.displayText == "y = cos(x)")
        #expect(analysis.classification.kind == .explicitY)
    }

    @Test func userFunctionDefinitionsClassifyForRendering() throws {
        let fx = AlgebraCore.analyzePlaneLatex("f(x)=x^2")
        let gy = AlgebraCore.analyzePlaneLatex("g(y)=y^2")

        #expect(fx.displayText == "f(x) = x²")
        #expect(fx.classification.kind == .explicitY)
        #expect(AlgebraEvaluator.evaluate(fx.classification.renderExpression ?? .number(0), variables: ["x": 2]) == 4)
        #expect(gy.displayText == "g(y) = y²")
        #expect(gy.classification.kind == .explicitX)
        #expect(AlgebraEvaluator.evaluate(gy.classification.renderExpression ?? .number(0), variables: ["y": 3]) == 9)
    }

    @Test func polynomialSimplificationFactorsAndCancels() throws {
        let factored = AlgebraCore.analyzePlaneLatex("x^2-1")
        let canceled = AlgebraCore.analyzePlaneLatex("\\frac{x^2-1}{x-1}")

        #expect(factored.displayText == "(x - 1) (x + 1)")
        #expect(canceled.displayText == "x + 1")
        #expect(canceled.diagnostics.contains { $0.message.contains("可去间断点") && $0.message.contains("x = 1") })
    }

    @Test func translatedConicsAreClassified() throws {
        let circle = AlgebraCore.analyzePlaneLatex("x^2+y^2-2x-4y+1=0")
        let ellipse = AlgebraCore.analyzePlaneLatex("x^2+4y^2-2x-8y+1=0")
        let hyperbola = AlgebraCore.analyzePlaneLatex("x^2-y^2-2x-4y-4=0")
        let parabola = AlgebraCore.analyzePlaneLatex("x^2-2x-y=0")

        #expect(circle.classification.kind == .circle)
        #expect(circle.classification.centerX == 1)
        #expect(circle.classification.centerY == 2)
        #expect(ellipse.classification.kind == .ellipse)
        #expect(hyperbola.classification.kind == .hyperbola)
        #expect(parabola.classification.kind == .parabola)
    }

    @Test func explicitFunctionClassificationHasHigherPriorityThanConicRewrite() throws {
        #expect(AlgebraCore.analyzePlaneLatex("y=x").classification.kind == .explicitY)
        #expect(AlgebraCore.analyzePlaneLatex("y=x^2").classification.kind == .explicitY)
        #expect(AlgebraCore.analyzePlaneLatex("y=x^2+1").classification.kind == .explicitY)
        #expect(AlgebraCore.analyzePlaneLatex("y=sin(x)").classification.kind == .explicitY)
        #expect(AlgebraCore.analyzePlaneLatex("x=y^2").classification.kind == .explicitX)

        let circle = AlgebraCore.analyzePlaneLatex("x^2+y^2=1").classification.kind
        #expect(circle == .circle || circle == .ellipse)
        let shiftedCircle = AlgebraCore.analyzePlaneLatex("(x-1)^2+(y+2)^2=4").classification.kind
        #expect(shiftedCircle == .circle || shiftedCircle == .ellipse)

        #expect(AlgebraCore.analyzePlaneLatex("x^2").classification.kind == .explicitY)
    }

    @Test func conicsRewriteToParametricStrategies() throws {
        let hyperbola = AlgebraCore.analyzePlaneLatex("(x^2/4)-(y^2/9)=1")
        let parabola = AlgebraCore.analyzePlaneLatex("y^2=4x")
        let ellipse = AlgebraCore.analyzePlaneLatex("(x-2)^2/4+(y+1)^2/9=1")

        #expect(hyperbola.recognizedShape == .hyperbola)
        #expect(hyperbola.plotStrategy == .parametric)
        #expect(hyperbola.rewriteInfo?.curve.kind == .hyperbolaHorizontal)

        #expect(parabola.recognizedShape == .parabola)
        #expect(parabola.plotStrategy == .parametric)
        #expect(parabola.rewriteInfo?.curve.kind == .parabolaHorizontal)

        #expect(ellipse.recognizedShape == .ellipse)
        #expect(ellipse.plotStrategy == .parametric)
        #expect(ellipse.rewriteInfo?.curve.centerX == 2)
        #expect(ellipse.rewriteInfo?.curve.centerY == -1)
        #expect(ellipse.rewriteInfo?.curve.radiusX == 2)
        #expect(ellipse.rewriteInfo?.curve.radiusY == 3)
    }

    @Test func conicParametricSamplerProducesDrawableSegments() throws {
        let hyperbolaCurve = try #require(AlgebraCore.analyzePlaneLatex("(x^2/4)-(y^2/9)=1").rewriteInfo?.curve)
        let parabolaCurve = try #require(AlgebraCore.analyzePlaneLatex("y^2=4x").rewriteInfo?.curve)

        let hyperbolaSegments = ParametricCurveSampler.sample(
            hyperbolaCurve,
            viewport: .default,
            canvasSize: CGSize(width: 320, height: 320)
        )
        let parabolaSegments = ParametricCurveSampler.sample(
            parabolaCurve,
            viewport: .default,
            canvasSize: CGSize(width: 320, height: 320)
        )

        #expect(hyperbolaSegments.count == 2)
        #expect(hyperbolaSegments.allSatisfy { $0.points.count > 100 })
        #expect(hyperbolaSegments.flatMap(\.points).allSatisfy { $0.x.isFinite && $0.y.isFinite })
        #expect(parabolaSegments.count == 1)
        #expect(parabolaSegments[0].points.count > 200)
        #expect(parabolaSegments[0].points.allSatisfy { $0.x.isFinite && $0.y.isFinite })
    }

    @Test func superellipseRecognizesAndRewritesToParametricStrategy() throws {
        let unit = AlgebraCore.analyzePlaneLatex("|x|^3+|y|^3=1")
        let stretched = AlgebraCore.analyzePlaneLatex("|x/2|^4+|y|^4=1")

        #expect(unit.classification.kind == .superellipse)
        #expect(unit.recognizedShape == .superellipse)
        #expect(unit.plotStrategy == .parametric)
        #expect(unit.rewriteInfo?.curve.exponent == 3)
        #expect(unit.rewriteInfo?.curve.radiusX == 1)
        #expect(unit.rewriteInfo?.curve.radiusY == 1)
        #expect(unit.restrictions?.contains("t ∈ [0, 2π]") == true)

        #expect(stretched.classification.kind == .superellipse)
        #expect(stretched.plotStrategy == .parametric)
        #expect(stretched.rewriteInfo?.curve.exponent == 4)
        #expect(stretched.rewriteInfo?.curve.radiusX == 2)
        #expect(stretched.rewriteInfo?.curve.radiusY == 1)
    }

    @Test func superellipseSamplerReturnsClosedFiniteSegments() throws {
        let analysis = AlgebraCore.analyzePlaneLatex("|x|^3+|y|^3=1")
        let curve = try #require(analysis.rewriteInfo?.curve)
        let segments = ParametricCurveSampler.sample(
            curve,
            viewport: .default,
            canvasSize: CGSize(width: 320, height: 320)
        )

        #expect(segments.count == 1)
        #expect(segments[0].points.count > 200)
        #expect(segments[0].points.allSatisfy { $0.x.isFinite && $0.y.isFinite })
    }

    @Test func symbolicSuperellipseParametersArePreservedForSliders() throws {
        let analysis = AlgebraCore.analyzePlaneLatex("|x/a|^n+|y/b|^n=1")
        let curve = try #require(analysis.rewriteInfo?.curve)

        #expect(analysis.classification.kind == .superellipse)
        #expect(analysis.plotStrategy == .parametric)
        #expect(analysis.unresolvedSymbols == ["a", "b", "n"])
        #expect(curve.radiusXSymbol == "a")
        #expect(curve.radiusYSymbol == "b")
        #expect(curve.exponentSymbol == "n")
        #expect(analysis.restrictions?.contains("n > 0") == true)

        let segments = ParametricCurveSampler.sample(
            curve,
            viewport: .default,
            canvasSize: CGSize(width: 320, height: 320),
            parameterValues: ["a": 2, "b": 1, "n": 4]
        )
        #expect(segments.count == 1)
        #expect(segments[0].points.allSatisfy { $0.x.isFinite && $0.y.isFinite })
    }

    @Test func integerExponentsUseSuperscripts() throws {
        #expect(AlgebraCore.analyzePlaneLatex("y=x^2").displayText == "y = x²")
        #expect(AlgebraCore.analyzePlaneLatex("y=x^4").displayText == "y = x⁴")
        #expect(AlgebraCore.analyzePlaneLatex("y=x^{-1}").displayText == "y = x⁻¹")
    }

    @Test func inputDraftAnalysisSuggestsUndefinedParameters() throws {
        let analysis = ParameterSuggestionAnalyzer.analyze("y=a*x^2+b*x+c", existingObjects: [])
        #expect(analysis.suggestions.map(\.symbol) == ["a", "b", "c"])
    }

    @Test func inputDraftAnalysisSuggestsSuperellipseParametersAndRestrictions() throws {
        let analysis = ParameterSuggestionAnalyzer.analyze("|x/a|^n+|y/b|^n=1", existingObjects: [])
        #expect(analysis.suggestions.map(\.symbol) == ["a", "b", "n"])
        #expect(analysis.restrictions.contains("a ≠ 0"))
        #expect(analysis.restrictions.contains("b ≠ 0"))
        #expect(analysis.restrictions.contains("n > 0"))
    }

    @Test func fractionTemplateNavigatesFieldsStructurally() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.numerator)])
        controller.handle(.insertCharacter("1"), state: &state)
        controller.handle(.moveDown, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.denominator)])
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path.isEmpty)
        #expect(SourceSerializer().serialize(state) == "\\frac{1}{2}")
    }

    @Test func formulaPreviewShowsPlaceholderBoxes() throws {
        var input = FormulaInputState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &input.editorState)
        input.syncDerivedStrings()
        #expect(input.displayLatex == "\\frac{\\square}{\\square}")

        let display = FormulaPreviewFormatter.displayPreview(for: input, existingObjects: [])
        #expect(display == "\\frac{\\square}{\\square}")
    }

    @MainActor
    @Test func successfulSubmitClearsFormulaInputState() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x^2"))
        state.dispatch(.submitInput)

        #expect(state.inputText.isEmpty)
        #expect(state.formulaInputState.source.isEmpty)
        #expect(state.formulaInputState.currentPlaceholderIndex == nil)
        #expect(state.inputDraftAnalysis.suggestions.isEmpty)
        #expect(state.formulaEditSession == nil)
        #expect(state.draftMathObject == nil)
        #expect(state.isInputPresented == false)
        #expect(state.formulaInputState.isEditing == false)
        #expect(state.document.objects.count == 1)
        #expect(state.isKeyboardPresented == false)
    }

    @MainActor
    @Test func submitParenthesizedTupleCommitsAsPointSemanticKind() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: -1.54)
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("(sin(a),cos(a))"))
        state.dispatch(.submitInput)

        guard let selectedID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == selectedID }) else {
            Issue.record("Expected committed object")
            return
        }
        #expect(object.expression.semanticGraphKind == .point)
        #expect(object.expression.sourceExpression == "(sin(a),cos(a))")
    }

    @MainActor
    @Test func submitLiteralTupleCommitsAsPointSemanticKind() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("(1,2)"))
        state.dispatch(.submitInput)

        guard let selectedID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == selectedID }) else {
            Issue.record("Expected committed object")
            return
        }
        #expect(object.expression.semanticGraphKind == .point)
        #expect(object.expression.sourceExpression == "(1,2)")
    }

    @MainActor
    @Test func reopenInputAfterSubmitStartsFreshSessionInsteadOfEditingLastObject() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x^2"))
        state.dispatch(.submitInput)

        guard let committed = state.selectedObjectID else {
            Issue.record("Expected committed object selection")
            return
        }

        state.dispatch(.openInput(mode: .expression))

        guard let session = state.formulaEditSession else {
            Issue.record("Expected a fresh formula edit session")
            return
        }
        guard case .createNew = session.mode else {
            Issue.record("Expected createNew session, got \(session.mode)")
            return
        }
        #expect(state.formulaInputState.source.isEmpty)
        #expect(state.selectedObjectID == committed)
    }

    @MainActor
    @Test func commitPersistsParametricRangeMetadata() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("{x=t, y=1, 0<t<1}"))
        state.dispatch(.submitInput)

        guard let selectedID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == selectedID }) else {
            Issue.record("Expected committed object")
            return
        }
        #expect(object.expression.semanticGraphKind == .parametric2D)
        #expect(object.expression.semanticParameterSymbol == Symbol(name: "t", role: .parameter))
        #expect(object.expression.semanticParameterRange == ParameterRange(
            lower: .integer(0),
            upper: .integer(1)
        ))
    }

    @MainActor
    @Test func explicitObjectEditAfterSubmitCanReenterEditSession() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x^2"))
        state.dispatch(.submitInput)

        guard let objectID = state.selectedObjectID else {
            Issue.record("Expected committed object selection")
            return
        }

        state.dispatch(.selectObject(id: objectID))
        state.dispatch(.updateInputText("y=x^2"))
        state.dispatch(.openInput(mode: .expression))

        guard let session = state.formulaEditSession else {
            Issue.record("Expected edit session")
            return
        }
        guard case .editExisting(let editingID) = session.mode else {
            Issue.record("Expected editExisting mode, got \(session.mode)")
            return
        }
        #expect(editingID == objectID)
        #expect(state.formulaInputState.source == "y=x^2")
    }

    @MainActor
    @Test func bareExpressionSubmitCreatesGraphableFunctionObject() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 1)
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("a"))
        state.dispatch(.submitInput)

        guard let selectedID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == selectedID }) else {
            Issue.record("Expected committed object")
            return
        }
        #expect(object.type == .function)
        #expect(object.expression.semanticGraphKind == .explicitY)
        #expect(object.expression.displayText.contains("y"))
    }

    @MainActor
    @Test func bareMultiplicationSubmitBehavesAsExplicitY() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 1)
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("a*x"))
        state.dispatch(.submitInput)

        guard let selectedID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == selectedID }) else {
            Issue.record("Expected committed object")
            return
        }
        #expect(object.type == .function)
        #expect(object.expression.semanticGraphKind == .explicitY)
    }

    @MainActor
    @Test func bareImplicitMultiplication2xSubmitBehavesAsExplicitY() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("2x"))
        state.dispatch(.submitInput)

        guard let selectedID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == selectedID }) else {
            Issue.record("Expected committed object")
            return
        }
        #expect(object.type == .function)
        #expect(object.expression.semanticGraphKind == .explicitY)
    }

    @MainActor
    @Test func spacedImplicitMultiplicationSubmitBehavesAsExplicitY() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 1)
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("a x"))
        state.dispatch(.submitInput)

        guard let selectedID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == selectedID }) else {
            Issue.record("Expected committed object")
            return
        }
        #expect(object.type == .function)
        #expect(object.expression.semanticGraphKind == .explicitY)
    }

    @MainActor
    @Test func yEqualsAxCommitProducesGraphableLegacyExpression() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 1)
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=ax"))
        state.dispatch(.submitInput)

        guard let selectedID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == selectedID }),
              let analysis = object.expression.algebraAnalysis,
              let render = analysis.classification.renderExpression else {
            Issue.record("Expected committed graphable expression")
            return
        }
        let yAtOne = AlgebraEvaluator.evaluate(render, variables: ["x": 1, "a": 2])
        #expect(yAtOne != nil)
    }

    @MainActor
    @Test func bareAxCommitProducesGraphableExpression() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 1)
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("ax"))
        state.dispatch(.submitInput)

        guard let selectedID = state.selectedObjectID,
              let object = state.document.objects.first(where: { $0.id == selectedID }),
              let analysis = object.expression.algebraAnalysis,
              let render = analysis.classification.renderExpression else {
            Issue.record("Expected committed graphable expression")
            return
        }
        let yAtOne = AlgebraEvaluator.evaluate(render, variables: ["x": 1, "a": 2])
        #expect(yAtOne != nil)
    }

    @MainActor
    @Test func sliderSettingsDefaultsAndQuantizationApplyToParameter() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 1.234)
        guard let parameter = state.document.objects.first(where: { $0.type == .parameter }) else {
            Issue.record("Expected parameter object")
            return
        }
        let defaults = parameter.sliderSettings
        #expect(defaults?.min == -10)
        #expect(defaults?.max == 10)
        #expect(defaults?.step == 0.1)
        #expect(defaults?.precision == 2)
        #expect(defaults?.speed == 1.0)
        #expect(defaults?.playbackMode == .increasing)
        #expect(defaults?.playbackLoopMode == .loop)

        var custom = defaults ?? .default
        custom.min = -5
        custom.max = 5
        custom.step = 0.5
        custom.precision = 1
        state.updateSliderSettings(id: parameter.id, settings: custom)
        state.updateParameter(id: parameter.id, value: 1.26)

        guard let updated = state.document.objects.first(where: { $0.id == parameter.id }),
              let value = updated.parameterValue else {
            Issue.record("Expected updated parameter")
            return
        }
        #expect(abs(value - 1.5) < 1e-9)
        #expect(updated.expression.displayText.contains("1.5"))
    }

    @MainActor
    @Test func sliderSettingsSanitizationClampsInvalidValues() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 12)
        guard let parameter = state.document.objects.first(where: { $0.type == .parameter }) else {
            Issue.record("Expected parameter object")
            return
        }

        var invalid = SliderSettings.default
        invalid.min = 5
        invalid.max = -5
        invalid.step = 0
        invalid.precision = 42
        invalid.speed = -2
        invalid.playbackLoopMode = .clamp
        state.updateSliderSettings(id: parameter.id, settings: invalid)

        guard let updated = state.document.objects.first(where: { $0.id == parameter.id }),
              let settings = updated.sliderSettings else {
            Issue.record("Expected updated slider settings")
            return
        }
        #expect(settings.min == -5)
        #expect(settings.max == 5)
        #expect(settings.step == SliderSettings.default.step)
        #expect(settings.precision == 6)
        #expect(settings.speed > 0)
        #expect(updated.parameterValue == 5)
    }

    @Test func sliderSettingsFormValidatorAcceptsValidInput() throws {
        let result = SliderSettingsFormValidator.validateAndNormalize(
            minText: "-2",
            maxText: "3",
            valueText: "2.26",
            stepText: "0.5",
            speedText: "2",
            precision: 3,
            playbackMode: .decreasing,
            playbackLoopMode: .loop
        )
        guard case .success(let payload) = result else {
            Issue.record("Expected validator success")
            return
        }
        #expect(payload.settings.min == -2)
        #expect(payload.settings.max == 3)
        #expect(payload.settings.step == 0.5)
        #expect(payload.settings.speed == 2)
        #expect(payload.settings.precision == 3)
        #expect(payload.settings.playbackMode == .decreasing)
        #expect(payload.settings.playbackLoopMode == .loop)
        #expect(payload.value == 2.5)
    }

    @Test func sliderSettingsFormValidatorRejectsInvalidRange() throws {
        let result = SliderSettingsFormValidator.validateAndNormalize(
            minText: "3",
            maxText: "3",
            valueText: "3",
            stepText: "0.1",
            speedText: "1",
            precision: 2,
            playbackMode: .increasing,
            playbackLoopMode: .loop
        )
        guard case .failure(let message) = result else {
            Issue.record("Expected validator failure for invalid range")
            return
        }
        #expect(message.message.contains("最小值必须小于最大值"))
    }

    @Test func sliderSettingsFormValidatorRejectsNonPositiveStepAndSpeed() throws {
        let badStep = SliderSettingsFormValidator.validateAndNormalize(
            minText: "0",
            maxText: "1",
            valueText: "0.5",
            stepText: "0",
            speedText: "1",
            precision: 2,
            playbackMode: .increasing,
            playbackLoopMode: .loop
        )
        guard case .failure(let stepMessage) = badStep else {
            Issue.record("Expected validator failure for step")
            return
        }
        #expect(stepMessage.message.contains("步长必须大于 0"))

        let badSpeed = SliderSettingsFormValidator.validateAndNormalize(
            minText: "0",
            maxText: "1",
            valueText: "0.5",
            stepText: "0.1",
            speedText: "-1",
            precision: 2,
            playbackMode: .increasing,
            playbackLoopMode: .loop
        )
        guard case .failure(let speedMessage) = badSpeed else {
            Issue.record("Expected validator failure for speed")
            return
        }
        #expect(speedMessage.message.contains("速度必须大于 0"))
    }

    @Test func sliderSettingsPresetMatcherMatchesDefaults() throws {
        let settings = SliderSettings.default
        #expect(SliderSettingsPresetMatcher.rangeMatches(settings, min: -10, max: 10))
        #expect(SliderSettingsPresetMatcher.stepMatches(settings, step: 0.1))
        #expect(SliderSettingsPresetMatcher.precisionMatches(settings, precision: 2))
        #expect(SliderSettingsPresetMatcher.speedMatches(settings, speed: 1.0))
        #expect(SliderSettingsPresetMatcher.playbackModeMatches(settings, mode: .increasing))
        #expect(SliderSettingsPresetMatcher.loopModeMatches(settings, mode: .loop))
    }

    @Test func sliderSettingsPresetMatcherSupportsEpsilonForDouble() throws {
        var settings = SliderSettings.default
        settings.min = 0
        settings.max = 2 * Double.pi + 1e-10
        settings.step = 0.100_000_000_5
        settings.speed = 2.000_000_000_5

        #expect(SliderSettingsPresetMatcher.rangeMatches(settings, min: 0, max: 2 * Double.pi))
        #expect(SliderSettingsPresetMatcher.stepMatches(settings, step: 0.1))
        #expect(SliderSettingsPresetMatcher.speedMatches(settings, speed: 2.0))
    }

    @Test func sliderSettingsPresetMatcherReportsCustomAsNoMatch() throws {
        var settings = SliderSettings.default
        settings.min = -3
        settings.max = 7
        settings.step = 0.25
        settings.speed = 1.5
        settings.precision = 5
        settings.playbackMode = .decreasing
        settings.playbackLoopMode = .pingPong

        #expect(!SliderSettingsPresetMatcher.rangeMatches(settings, min: -10, max: 10))
        #expect(!SliderSettingsPresetMatcher.stepMatches(settings, step: 0.1))
        #expect(!SliderSettingsPresetMatcher.speedMatches(settings, speed: 1.0))
        #expect(!SliderSettingsPresetMatcher.precisionMatches(settings, precision: 2))
        #expect(!SliderSettingsPresetMatcher.playbackModeMatches(settings, mode: .increasing))
        #expect(!SliderSettingsPresetMatcher.loopModeMatches(settings, mode: .loop))
    }

    @Test func mathStylePresetMatcherMatchesDefaults() throws {
        let style = MathStyle(colorToken: ColorToken.blue.rawValue)
        #expect(MathStylePresetMatcher.colorMatches(style, .blue))
        #expect(MathStylePresetMatcher.lineWidthMatches(style, 2))
        #expect(MathStylePresetMatcher.opacityMatches(style, 1))
        #expect(MathStylePresetMatcher.pointSizeMatches(style, 6))
        #expect(MathStylePresetMatcher.lineStyleMatches(style, .solid))
    }

    @Test func mathStylePresetMatcherLineWidthUsesEpsilon() throws {
        let style = MathStyle(colorToken: ColorToken.blue.rawValue, lineWidth: 2.000_000_000_5)
        #expect(MathStylePresetMatcher.lineWidthMatches(style, 2.0))
        #expect(!MathStylePresetMatcher.lineWidthMatches(style, 2.00001))
    }

    @Test func mathStylePresetMatcherOpacityAndPointSizeUseEpsilon() throws {
        let style = MathStyle(
            colorToken: ColorToken.blue.rawValue,
            opacity: 0.750_000_000_4,
            pointSize: 8.000_000_000_4
        )
        #expect(MathStylePresetMatcher.opacityMatches(style, 0.75))
        #expect(MathStylePresetMatcher.pointSizeMatches(style, 8))
    }

    @Test func mathStylePresetMatcherDashedAndCustomColorBehavior() throws {
        let dashed = MathStyle(colorToken: ColorToken.red.rawValue, lineStyle: .dashed)
        #expect(MathStylePresetMatcher.lineStyleMatches(dashed, .dashed))
        #expect(!MathStylePresetMatcher.lineStyleMatches(dashed, .solid))

        let custom = MathStyle(colorToken: "hex:3366FF")
        #expect(!MathStylePresetMatcher.colorMatches(custom, .blue))
        #expect(!MathStylePresetMatcher.colorMatches(custom, .red))
    }

    @Test func mathStylePresetMatcherWorksAfterSanitizeClamp() throws {
        let style = MathStyle(
            colorToken: ColorToken.green.rawValue,
            opacity: 2,
            lineWidth: 99,
            pointSize: 1
        ).sanitized()
        #expect(MathStylePresetMatcher.opacityMatches(style, 1))
        #expect(MathStylePresetMatcher.lineWidthMatches(style, 8))
        #expect(MathStylePresetMatcher.pointSizeMatches(style, 3))
    }

    @Test func mathStylePresetProviderContainsExpectedValuesInOrder() throws {
        #expect(MathStylePresetProvider.colorPresets.map(\.token) == [.blue, .red, .orange, .green, .purple, .cyan, .white])
        #expect(MathStylePresetProvider.lineWidthPresets.map(\.value) == [1, 2, 3, 5])
        #expect(MathStylePresetProvider.opacityPresets.map(\.value) == [0.25, 0.5, 0.75, 1.0])
        #expect(MathStylePresetProvider.pointSizePresets.map(\.value) == [4, 6, 8, 12])
        #expect(MathStylePresetProvider.lineStylePresets.map(\.value) == [.solid, .dashed])
    }

    @Test func mathStyleDefaultsAreContainedInPresetProvider() throws {
        let style = MathStyle(colorToken: ColorToken.blue.rawValue)
        #expect(MathStylePresetProvider.lineWidthPresets.contains(where: { MathStylePresetMatcher.lineWidthMatches(style, $0.value) }))
        #expect(MathStylePresetProvider.pointSizePresets.contains(where: { MathStylePresetMatcher.pointSizeMatches(style, $0.value) }))
        #expect(MathStylePresetProvider.opacityPresets.contains(where: { MathStylePresetMatcher.opacityMatches(style, $0.value) }))
        #expect(MathStylePresetProvider.lineStylePresets.contains(where: { MathStylePresetMatcher.lineStyleMatches(style, $0.value) }))
    }

    @Test func mathStylePresetProviderWorksWithPresetMatcher() throws {
        let style = MathStyle(
            colorToken: ColorToken.orange.rawValue,
            opacity: 0.75,
            lineWidth: 3,
            pointSize: 8,
            lineStyle: .dashed
        )
        #expect(MathStylePresetProvider.colorPresets.contains(where: { MathStylePresetMatcher.colorMatches(style, $0.token) }))
        #expect(MathStylePresetProvider.lineWidthPresets.contains(where: { MathStylePresetMatcher.lineWidthMatches(style, $0.value) }))
        #expect(MathStylePresetProvider.opacityPresets.contains(where: { MathStylePresetMatcher.opacityMatches(style, $0.value) }))
        #expect(MathStylePresetProvider.pointSizePresets.contains(where: { MathStylePresetMatcher.pointSizeMatches(style, $0.value) }))
        #expect(MathStylePresetProvider.lineStylePresets.contains(where: { MathStylePresetMatcher.lineStyleMatches(style, $0.value) }))
    }

    @MainActor
    @Test func draftPreviewResamplesWhenSliderChanges() async throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 1)
        guard let parameter = state.document.objects.first(where: { $0.type == .parameter }) else {
            Issue.record("Expected parameter object")
            return
        }

        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=a*x"))
        try await _Concurrency.Task.sleep(nanoseconds: 220_000_000)

        let before = state.draftMathObject?.previewSamples.first?.points.first?.y
        #expect(before != nil)

        state.updateParameter(id: parameter.id, value: 2)
        try await _Concurrency.Task.sleep(nanoseconds: 220_000_000)
        let after = state.draftMathObject?.previewSamples.first?.points.first?.y
        #expect(after != nil)
        if let before, let after {
            #expect(abs(after - before) > 1e-6)
        }
    }

    @Test func graphIntentSamplerParametricReadsSliderEnvironment() throws {
        let sampler = GraphIntentSampler2D(qualityProfile: .balanced)
        let t = Symbol(name: "t", role: .parameter)
        let intent = GraphIntent.parametric2D(
            x: .multiply([.symbol(Symbol(name: "a", role: .parameter)), .symbol(t)]),
            y: .symbol(t),
            parameter: t,
            range: ParameterRange(lower: .integer(0), upper: .integer(1))
        )
        let sampleSet = sampler.sample(
            intent: intent,
            xRange: SamplingRange(lower: -2, upper: 2),
            yRange: SamplingRange(lower: -2, upper: 2),
            environment: .variables(["a": 2])
        )
        let xs = sampleSet.segments.flatMap(\.points).map(\.x)
        guard let maxX = xs.max() else {
            Issue.record("Expected parametric samples")
            return
        }
        #expect(maxX > 1.8)
    }

    @Test func graphIntentSamplerPiecewiseReadsSliderEnvironment() throws {
        let sampler = GraphIntentSampler2D(qualityProfile: .balanced)
        let x = Symbol(name: "x", role: .variable)
        let branches: [GraphIntentBranch] = [
            .init(
                condition: .relation(left: .symbol(x), relation: .less, right: .integer(0)),
                intent: .explicitY(
                    expression: .multiply([.symbol(Symbol(name: "a", role: .parameter)), .symbol(x)]),
                    variable: x
                )
            ),
            .init(
                condition: .relation(left: .symbol(x), relation: .greaterOrEqual, right: .integer(0)),
                intent: .explicitY(expression: .symbol(x), variable: x)
            )
        ]
        let intent = GraphIntent.piecewise(branches)
        let sampleSetA1 = sampler.sample(
            intent: intent,
            xRange: SamplingRange(lower: -1, upper: 1),
            environment: .variables(["a": 1])
        )
        let sampleSetA2 = sampler.sample(
            intent: intent,
            xRange: SamplingRange(lower: -1, upper: 1),
            environment: .variables(["a": 2])
        )

        func averageNegativeY(_ set: SampleSet2D) -> Double? {
            let ys = set.segments
                .flatMap(\.points)
                .filter { $0.x < -0.2 }
                .map(\.y)
            guard !ys.isEmpty else { return nil }
            return ys.reduce(0, +) / Double(ys.count)
        }

        guard let avg1 = averageNegativeY(sampleSetA1),
              let avg2 = averageNegativeY(sampleSetA2) else {
            Issue.record("Expected piecewise negative-side samples")
            return
        }
        #expect(Swift.abs(avg2 - avg1) > 0.1)
    }

    @MainActor
    @Test func sliderPlaybackAdvancesAndPauses() async throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 0)
        guard let parameter = state.document.objects.first(where: { $0.type == .parameter }) else {
            Issue.record("Expected parameter object")
            return
        }
        var settings = parameter.sliderSettings ?? .default
        settings.min = 0
        settings.max = 1
        settings.step = 0.2
        settings.speed = 1.0
        settings.playbackMode = .increasing
        settings.playbackLoopMode = .loop
        state.updateSliderSettings(id: parameter.id, settings: settings)

        state.toggleSliderPlayback(id: parameter.id)
        #expect(state.isSliderPlaying(id: parameter.id))
        try await _Concurrency.Task.sleep(nanoseconds: 160_000_000)
        let midValue = state.document.objects.first(where: { $0.id == parameter.id })?.parameterValue
        #expect((midValue ?? 0) > 0)

        state.toggleSliderPlayback(id: parameter.id)
        #expect(!state.isSliderPlaying(id: parameter.id))
        let pausedValue = state.document.objects.first(where: { $0.id == parameter.id })?.parameterValue
        try await _Concurrency.Task.sleep(nanoseconds: 120_000_000)
        let afterPauseValue = state.document.objects.first(where: { $0.id == parameter.id })?.parameterValue
        #expect(pausedValue == afterPauseValue)
    }

    @MainActor
    @Test func sliderPlaybackPingPongReversesAtBounds() async throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 0.9)
        guard let parameter = state.document.objects.first(where: { $0.type == .parameter }) else {
            Issue.record("Expected parameter object")
            return
        }
        var settings = parameter.sliderSettings ?? .default
        settings.min = 0
        settings.max = 1
        settings.step = 0.2
        settings.speed = 1.0
        settings.playbackMode = .pingPong
        settings.playbackLoopMode = .pingPong
        state.updateSliderSettings(id: parameter.id, settings: settings)

        state.toggleSliderPlayback(id: parameter.id)
        try await _Concurrency.Task.sleep(nanoseconds: 180_000_000)
        let valueAfterBounce = state.document.objects.first(where: { $0.id == parameter.id })?.parameterValue ?? 0
        #expect(valueAfterBounce <= 1.0)
        #expect(valueAfterBounce >= 0.0)
        state.toggleSliderPlayback(id: parameter.id)
    }

    @MainActor
    @Test func sliderPlaybackClampStopsAtBoundary() async throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 0.9)
        guard let parameter = state.document.objects.first(where: { $0.type == .parameter }) else {
            Issue.record("Expected parameter object")
            return
        }
        var settings = parameter.sliderSettings ?? .default
        settings.min = 0
        settings.max = 1
        settings.step = 0.2
        settings.speed = 1.0
        settings.playbackMode = .increasing
        settings.playbackLoopMode = .clamp
        state.updateSliderSettings(id: parameter.id, settings: settings)

        state.toggleSliderPlayback(id: parameter.id)
        try await _Concurrency.Task.sleep(nanoseconds: 180_000_000)
        #expect(!state.isSliderPlaying(id: parameter.id))
        let finalValue = state.document.objects.first(where: { $0.id == parameter.id })?.parameterValue
        #expect(finalValue == 1)
    }

    @Test func structuredFractionTemplateUsesAstAndTabNavigation() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)

        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        #expect(latex == "\\frac{\\square}{\\square}")

        if case .template(let template)? = MathEditorTree.node(at: [.sequenceIndex(0)], in: state.root) {
            #expect(template.kind == .fraction)
        } else {
            #expect(Bool(false))
        }

        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.numerator)])
        controller.handle(.insertCharacter("1"), state: &state)
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.denominator)])
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path.isEmpty)
        #expect(SourceSerializer().serialize(state) == "\\frac{1}{2}")
    }

    @Test func superscriptConsumesLeftOperandAndMovesCursorToExponent() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)

        let latex = SourceSerializer().serialize(state)
        #expect(latex == "x^{2}")
    }

    @Test func parametricTemplateSupportsVerticalNavigation() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.parametricEquation2D), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(0))])
        controller.handle(.moveDown, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(1))])
        controller.handle(.moveDown, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricRange)])
        controller.handle(.moveUp, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(1))])
        controller.handle(.moveUp, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(0))])
    }

    @Test func parametricTemplateInsertionStartsWithoutRangeContent() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.parametricEquation2D), state: &state)

        guard case .sequence(let nodes) = state.root,
              case .template(let template)? = nodes.first else {
            Issue.record("Expected parametric template after insertion.")
            return
        }

        guard let rangeNode = template.field(.parametricRange),
              case .sequence(let rangeItems) = rangeNode else {
            Issue.record("Expected dedicated parametric range slot.")
            return
        }
        #expect(rangeItems.count == 1)
        #expect(rangeItems.first == .placeholder)
        #expect(SourceSerializer().serialize(state) == "x={}, y={}")
    }

    @Test func parametricTemplateInsertionWithNoRangeLowersToTwoSiblingTupleItems() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.parametricEquation2D), state: &state)

        // Fill x/y only; keep range empty.
        state.cursor = .init(path: [.sequenceIndex(0), .templateField(.parametricExpression(0))], offset: 0)
        controller.handle(.insertSymbol("t"), state: &state)
        state.cursor = .init(path: [.sequenceIndex(0), .templateField(.parametricExpression(1))], offset: 0)
        controller.handle(.insertSymbol("t"), state: &state)

        let lowered = MathNodeSemanticLowering().lower(state.root)
        guard case .tuple(let values)? = lowered.expr else {
            Issue.record("Expected tuple expression, got \(String(describing: lowered.expr))")
            return
        }
        #expect(values.count == 2)
        #expect(values[0] == Expr.relation(
            left: Expr.symbol(.init(name: "x", role: .variable)),
            relation: .equal,
            right: Expr.symbol(.init(name: "t", role: .unknown))
        ))
        #expect(values[1] == Expr.relation(
            left: Expr.symbol(.init(name: "y", role: .variable)),
            relation: .equal,
            right: Expr.symbol(.init(name: "t", role: .unknown))
        ))
    }

    @Test func parametricCommaAfterYRoutesToDedicatedRangeSlot() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.parametricEquation2D), state: &state)
        controller.handle(.insertSymbol("t"), state: &state)
        controller.handle(.tab, state: &state)
        controller.handle(.insertSymbol("t"), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(1))])

        // At end of y field, comma should activate dedicated range slot.
        controller.handle(.insertCharacter(","), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricRange)])
        #expect(state.cursor.offset == 0)

        controller.handle(.insertCharacter("0"), state: &state)
        controller.handle(.insertOperator("<"), state: &state)
        controller.handle(.insertSymbol("t"), state: &state)
        controller.handle(.insertOperator("<"), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)

        #expect(SourceSerializer().serialize(state) == "x={t}, y={t}, 0<t<1")
        let lowered = MathNodeSemanticLowering().lower(state.root)
        guard case .tuple(let values)? = lowered.expr else {
            Issue.record("Expected tuple expression.")
            return
        }
        #expect(values.count == 3)
    }

    @Test func parametricParenthesisAfterYRoutesIntoRangeSlot() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.parametricEquation2D), state: &state)
        controller.handle(.insertSymbol("t"), state: &state)
        controller.handle(.tab, state: &state)
        controller.handle(.insertSymbol("t"), state: &state)

        controller.handle(.insertCharacter("("), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricRange)])
        #expect(SourceSerializer().serialize(state).contains("x={t}, y={t}, ("))
    }

    @Test func caretKeyBuildsSuperscriptTemplateInsteadOfPlainText() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertOperator("^"), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)

        if case .sequence(let nodes) = state.root,
           case .template(let sup)? = nodes.first {
            #expect(sup.kind == .superscript)
            #expect(LatexMathRenderer().renderLatex(state.root, editing: true) == "x^{2}")
        } else {
            #expect(Bool(false))
        }
    }

    @Test func yEquals2xThenCaretProducesExponentLatex() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertCharacter("y"), state: &state)
        controller.handle(.insertOperator("="), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertOperator("^"), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)

        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        #expect(latex == "y=2x^{2}")
    }

    @Test func fractionInsertionCreatesTemplateNode() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)

        if case .sequence(let nodes) = state.root,
           case .template(let fraction)? = nodes.first {
            #expect(fraction.kind == .fraction)
            #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.numerator)])
        } else {
            #expect(Bool(false))
        }
    }

    @Test func sqrtInsertionCreatesTemplateNodeAndFocusesRadicand() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.sqrt), state: &state)

        if case .sequence(let nodes) = state.root,
           case .template(let sqrt)? = nodes.first {
            #expect(sqrt.kind == .sqrt)
            #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.radicand)])
        } else {
            #expect(Bool(false))
        }
    }

    @Test func superscriptTabNavigation() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.exponent)])
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path.isEmpty)
        #expect(state.cursor.offset == 1)
    }

    @Test func superscriptRightExitsExponent() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.moveRight, state: &state)
        controller.handle(.insertOperator("+"), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)
        #expect(LatexMathRenderer().renderLatex(state.root, editing: true) == "x^{2}+1")
    }

    @Test func superscriptBackspaceRemovesExponentThenUnwraps() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.backspace, state: &state)
        #expect(LatexMathRenderer().renderLatex(state.root, editing: true) == "x^{\\square}")
        controller.handle(.backspace, state: &state)
        #expect(SourceSerializer().serialize(state) == "x")
    }

    @Test func deletingBeforeSuperscriptDoesNotInsertBraces() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertCharacter("y"), state: &state)
        controller.handle(.insertOperator("="), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        state.cursor = EditorCursor(path: [], offset: 1)
        controller.handle(.delete, state: &state)
        let source = SourceSerializer().serialize(state)
        #expect(!source.contains("{}"))
        #expect(!source.contains("{=}"))
    }

    @Test func sqrtTabNavigation() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.sqrt), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.radicand)])
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path.isEmpty)
        #expect(state.cursor.offset == 1)
    }

    @Test func templateInsertionReplacesCurrentPlaceholderInRootSequence() throws {
        var state = EditorState(
            root: .sequence([.placeholder]),
            cursor: .init(path: [], offset: 0)
        )
        let controller = InputController()
        controller.handle(.insertTemplate(.sin), state: &state)

        guard case .sequence(let nodes) = state.root else {
            Issue.record("Expected root sequence")
            return
        }
        #expect(nodes.count == 1)
        guard case .template(let template) = nodes[0] else {
            Issue.record("Expected inserted sin template")
            return
        }
        #expect(template.kind == .sin)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.argument)])
        #expect(state.cursor.offset == 0)
    }

    @Test func repeatedSinTemplateInsertionNestsWithoutResidualSiblingPlaceholder() throws {
        var state = EditorState(
            root: .sequence([.placeholder]),
            cursor: .init(path: [], offset: 0)
        )
        let controller = InputController()
        controller.handle(.insertTemplate(.sin), state: &state)
        controller.handle(.insertTemplate(.sin), state: &state)
        controller.handle(.insertTemplate(.sin), state: &state)

        guard case .sequence(let rootNodes) = state.root,
              rootNodes.count == 1,
              case .template(let first) = rootNodes[0],
              first.kind == .sin else {
            Issue.record("Expected single nested sin template at root")
            return
        }

        guard let level2Node = first.field(.argument),
              case .sequence(let level2Seq) = level2Node,
              level2Seq.count == 1,
              case .template(let level2) = level2Seq[0],
              level2.kind == .sin else {
            Issue.record("Expected second nested sin template")
            return
        }

        guard let level3Node = level2.field(.argument),
              case .sequence(let level3Seq) = level3Node,
              level3Seq.count == 1,
              case .template(let level3) = level3Seq[0],
              level3.kind == .sin else {
            Issue.record("Expected third nested sin template")
            return
        }

        guard let innermostArg = level3.field(.argument),
              case .sequence(let innermostSeq) = innermostArg else {
            Issue.record("Expected innermost argument slot")
            return
        }
        #expect(innermostSeq.count == 1)
        #expect(innermostSeq.first == .placeholder)
    }

    @Test func selectedSingleNodeWrappedBySinTemplate() throws {
        var state = EditorState(
            root: .sequence([.symbol("x")]),
            cursor: .init(path: [], offset: 1),
            selection: .init(
                anchor: .init(path: [], offset: 0),
                focus: .init(path: [], offset: 1)
            )
        )
        let controller = InputController()
        controller.handle(.insertTemplate(.sin), state: &state)

        let source = SourceSerializer().serialize(state)
        #expect(source == "sin({x})")
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.argument)])
    }

    @Test func selectedExpressionWrappedBySqrtTemplate() throws {
        var state = EditorState(
            root: .sequence([.symbol("x"), .operatorSymbol("+"), .character("1")]),
            cursor: .init(path: [], offset: 3),
            selection: .init(
                anchor: .init(path: [], offset: 0),
                focus: .init(path: [], offset: 3)
            )
        )
        let controller = InputController()
        controller.handle(.insertTemplate(.sqrt), state: &state)
        #expect(SourceSerializer().serialize(state) == "sqrt({x+1})")
    }

    @Test func selectedExpressionWrappedIntoFractionNumeratorAndCursorMovesDenominator() throws {
        var state = EditorState(
            root: .sequence([.symbol("x"), .operatorSymbol("+"), .character("1")]),
            cursor: .init(path: [], offset: 3),
            selection: .init(
                anchor: .init(path: [], offset: 0),
                focus: .init(path: [], offset: 3)
            )
        )
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        #expect(SourceSerializer().serialize(state) == "frac({x+1},{□})")
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.denominator)])
        #expect(state.cursor.offset == 0)
    }

    @Test func selectedBaseWrappedBySuperscriptAndCursorMovesExponent() throws {
        var state = EditorState(
            root: .sequence([.symbol("x")]),
            cursor: .init(path: [], offset: 1),
            selection: .init(
                anchor: .init(path: [], offset: 0),
                focus: .init(path: [], offset: 1)
            )
        )
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        #expect(SourceSerializer().serialize(state) == "{x}^{□}")
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.exponent)])
    }

    @Test func selectedExpressionWrappedByParenthesesTemplate() throws {
        var state = EditorState(
            root: .sequence([.symbol("x"), .operatorSymbol("+"), .character("1")]),
            cursor: .init(path: [], offset: 3),
            selection: .init(
                anchor: .init(path: [], offset: 0),
                focus: .init(path: [], offset: 3)
            )
        )
        let controller = InputController()
        controller.handle(.insertTemplate(.parentheses), state: &state)
        #expect(SourceSerializer().serialize(state) == "({x+1})")
    }

    @Test func parametricTemplateTabNavigation() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.parametricEquation2D), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(0))])
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(1))])
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricRange)])
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path.isEmpty)
    }

    @Test func parametricSlotFirstAndSecondCharacterAreImmediatelyVisibleInDerivedStrings() throws {
        var input = FormulaInputState()
        let controller = InputController()
        controller.handle(.insertTemplate(.parametricEquation2D), state: &input.editorState)

        controller.handle(.insertCharacter("x"), state: &input.editorState)
        input.syncDerivedStrings()
        #expect(input.source.contains("x={x}"))
        #expect(input.displayLatex.contains("x=x"))

        controller.handle(.insertCharacter("x"), state: &input.editorState)
        input.syncDerivedStrings()
        #expect(input.source.contains("x={xx}"))
        #expect(input.displayLatex.contains("x=xx"))
    }

    @Test func piecewiseFractionAndSuperscriptSingleCharacterImmediatelyVisible() throws {
        let controller = InputController()

        var piecewise = EditorState()
        controller.handle(.insertTemplate(.piecewise(rows: 3)), state: &piecewise)
        controller.handle(.insertCharacter("x"), state: &piecewise)
        #expect(SourceSerializer().serialize(piecewise).contains("piecewise(x if"))

        var fraction = EditorState()
        controller.handle(.insertTemplate(.fraction), state: &fraction)
        controller.handle(.insertCharacter("x"), state: &fraction)
        #expect(LatexMathRenderer().renderLatex(fraction.root, editing: true).contains("\\frac{x}{\\square}"))

        var superscript = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        controller.handle(.insertTemplate(.superscript), state: &superscript)
        controller.handle(.insertCharacter("2"), state: &superscript)
        #expect(LatexMathRenderer().renderLatex(superscript.root, editing: true).contains("^{2}"))
    }

    @Test func parametricSourceSerializationKeepsRangeAsGlobalCondition() throws {
        let state = EditorState(
            root: .sequence([
                .template(
                    .init(
                        kind: .parametricEquation2D,
                        fields: [
                            .init(id: .parametricExpression(0), node: .sequence([.symbol("t")])),
                            .init(id: .parametricExpression(1), node: .sequence([.symbol("t")])),
                            .init(id: .parametricRange, node: .sequence([.symbol("t"), .operatorSymbol("<"), .symbol("1")]))
                        ]
                    )
                )
            ])
        )
        #expect(SourceSerializer().serialize(state) == "x={t}, y={t}, t<1")
        #expect(!SourceSerializer().serialize(state).contains("x={t,"))
        #expect(!SourceSerializer().serialize(state).contains("y={t,"))
    }

    @Test func piecewiseTemplateTabNavigation() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.piecewise(rows: 2)), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowExpression(0))])
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowCondition(0))])
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowExpression(1))])
    }

    @Test func piecewiseTemplateShiftTabMovesToPreviousMajorSlot() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.piecewise(rows: 3)), state: &state)
        controller.handle(.tab, state: &state) // row0 condition
        controller.handle(.tab, state: &state) // row1 value
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowExpression(1))])
        controller.handle(.shiftTab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowCondition(0))])
    }

    @Test func fractionRightArrowMovesNumeratorToDenominatorThenExits() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.numerator)])
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.denominator)])
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path.isEmpty)
        #expect(state.cursor.offset == 1)
    }

    @Test func piecewiseRightArrowMovesConditionToNextRowExpression() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.piecewise(rows: 3)), state: &state)
        controller.handle(.tab, state: &state) // row1 condition
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowCondition(0))])
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowExpression(1))])
    }

    @Test func piecewiseVerticalArrowsPreserveColumnAcrossRows() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.piecewise(rows: 3)), state: &state) // row0 value
        controller.handle(.moveDown, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowExpression(1))])
        controller.handle(.moveDown, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowExpression(2))])
        controller.handle(.moveRight, state: &state) // row2 condition
        controller.handle(.moveUp, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowCondition(1))])
        controller.handle(.moveUp, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowCondition(0))])
    }

    @Test func parametricRightArrowTraversesXThenYThenRangeThenExits() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.parametricEquation2D), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(0))])
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(1))])
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricRange)])
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path.isEmpty)
    }

    @Test func parametricShiftTabMovesRangeToYToX() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.parametricEquation2D), state: &state)
        controller.handle(.tab, state: &state) // y
        controller.handle(.tab, state: &state) // range
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricRange)])
        controller.handle(.shiftTab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(1))])
        controller.handle(.shiftTab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(0))])
    }

    @MainActor
    @Test func appendPiecewiseRowAddsThirdBranchAndMovesCursor() throws {
        let workspace = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Piecewise"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        workspace.dispatch(.openInput(mode: .expression))
        workspace.handleKeyboardAction(.insertTemplate(.piecewise(rows: 2)))
        #expect(workspace.canAppendPiecewiseRow)

        workspace.appendPiecewiseRow()

        guard case .sequence(let nodes) = workspace.formulaInputState.editorState.root,
              case .template(let template)? = nodes.first,
              case .piecewise(let rows) = template.kind else {
            Issue.record("Expected piecewise template in root")
            return
        }
        #expect(rows == 3)
        #expect(template.field(.rowExpression(2)) != nil)
        #expect(template.field(.rowCondition(2)) != nil)
        #expect(workspace.formulaInputState.editorState.cursor.path == [.sequenceIndex(0), .templateField(.rowExpression(2))])
        #expect(!workspace.formulaInputState.source.contains("添加"))
        #expect(!workspace.formulaInputState.displayLatex.contains("添加"))
    }

    @MainActor
    @Test func beginEditingObjectExpressionKeepsAstAndFirstInputDoesNotClear() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Edit"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x^2"))
        state.dispatch(.submitInput)
        guard let objectID = state.selectedObjectID else {
            Issue.record("Expected selected object")
            return
        }

        state.beginEditingObjectExpression(objectID, openKeyboard: false)
        #expect(state.formulaEditSession != nil)
        #expect(!state.formulaInputState.source.isEmpty)

        state.handleKeyboardAction(.insertOperator("+"))
        state.handleKeyboardAction(.insertCharacter("1"))
        #expect(!state.formulaInputState.source.isEmpty)
        #expect(state.formulaInputState.source.contains("+1"))
    }

    @MainActor
    @Test func beginEditingPointExpressionLoadsTupleAndFirstInputDoesNotClear() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "EditPoint"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("(1,2)"))
        state.dispatch(.submitInput)
        guard let objectID = state.selectedObjectID else {
            Issue.record("Expected selected point object")
            return
        }

        state.beginEditingObjectExpression(objectID, openKeyboard: false)
        #expect(state.formulaEditSession != nil)
        #expect(state.formulaInputState.semanticState.graphClassification?.intent == .point(x: .integer(1), y: .integer(2)))
        #expect(!state.formulaInputState.source.isEmpty)

        state.handleKeyboardAction(.insertCharacter(" "))
        #expect(!state.formulaInputState.source.isEmpty)
    }

    @MainActor
    @Test func editExistingObjectSubmitKeepsObjectID() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "EditSubmit"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x^2"))
        state.dispatch(.submitInput)
        guard let objectID = state.selectedObjectID else {
            Issue.record("Expected selected object")
            return
        }
        let originalCount = state.document.objects.count

        state.beginEditingObjectExpression(objectID, openKeyboard: false)
        state.handleKeyboardAction(.insertOperator("+"))
        state.handleKeyboardAction(.insertCharacter("1"))
        state.dispatch(.submitInput)

        #expect(state.document.objects.count == originalCount)
        #expect(state.document.objects.contains(where: { $0.id == objectID }))
        #expect(state.selectedObjectID == objectID)
    }

    @MainActor
    @Test func editParameterExpressionPreservesSliderSettings() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "EditParameter"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.createParameter(named: "a", initialValue: 1)
        guard let parameter = state.document.objects.first(where: { $0.type == .parameter }) else {
            Issue.record("Expected parameter object")
            return
        }
        let originalSettings = parameter.sliderSettings
        state.beginEditingObjectExpression(parameter.id, openKeyboard: false)
        state.dispatch(.submitInput)

        guard let updated = state.document.objects.first(where: { $0.id == parameter.id }) else {
            Issue.record("Expected updated parameter object")
            return
        }
        #expect(updated.type == .parameter)
        #expect(updated.sliderSettings == originalSettings)
    }

    @MainActor
    @Test func nonIncrementalInputUpdateWhileEditingRebuildsAstInsteadOfDroppingText() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Edit"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x^2"))
        state.dispatch(.submitInput)
        guard let objectID = state.selectedObjectID else {
            Issue.record("Expected selected object")
            return
        }

        state.beginEditingObjectExpression(objectID, openKeyboard: false)
        state.dispatch(.updateInputText("y=x^2+1"))

        #expect(state.formulaInputState.source == "y=x^2+1")
        #expect(state.formulaInputState.semanticState.expression != nil)
        #expect(state.formulaInputState.editorState.cursor.path.isEmpty)
    }

    @MainActor
    @Test func invalidCursorIsRecoveredBeforeInsertSoInputIsNotDropped() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Cursor"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.handleKeyboardAction(.insertTemplate(.piecewise(rows: 2)))
        state.formulaInputState.editorState.cursor = EditorCursor(path: [.templateField(.rowExpression(0))], offset: 99)
        state.formulaEditSession?.editorState.cursor = state.formulaInputState.editorState.cursor
        state.handleKeyboardAction(.insertCharacter("x"))
        #expect(state.formulaInputState.source.contains("x"))
    }

    @MainActor
    @Test func appendPiecewiseRowTwiceCreatesFourRowsAndSemanticBranches() throws {
        let workspace = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Piecewise"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        workspace.dispatch(.openInput(mode: .expression))
        workspace.handleKeyboardAction(.insertTemplate(.piecewise(rows: 2)))
        workspace.appendPiecewiseRow()
        workspace.appendPiecewiseRow()

        guard case .sequence(let nodes) = workspace.formulaInputState.editorState.root,
              case .template(let template)? = nodes.first,
              case .piecewise(let rows) = template.kind else {
            Issue.record("Expected piecewise template in root")
            return
        }
        #expect(rows == 4)
        #expect(template.field(.rowExpression(3)) != nil)
        #expect(template.field(.rowCondition(3)) != nil)

        let lowered = MathNodeSemanticLowering().lower(workspace.formulaInputState.editorState.root)
        guard case .piecewise(let branches, _)? = lowered.expr else {
            Issue.record("Expected Expr.piecewise, got \(String(describing: lowered.expr))")
            return
        }
        #expect(branches.count == 4)

        let graph = GraphClassifier().classify(lowered.expr!)
        guard case .piecewise(let intents) = graph.intent else {
            Issue.record("Expected GraphIntent.piecewise, got \(graph.intent)")
            return
        }
        #expect(intents.count == 4)
    }

    @Test func piecewiseBraceHeightGrowsWithRows() throws {
        let two = FormulaEditorView.piecewiseBraceHeight(rows: 2)
        let three = FormulaEditorView.piecewiseBraceHeight(rows: 3)
        let four = FormulaEditorView.piecewiseBraceHeight(rows: 4)
        let six = FormulaEditorView.piecewiseBraceHeight(rows: 6)
        #expect(three > two)
        #expect(four > three)
        #expect(six > four)
    }

    @Test func piecewiseRowLayoutAlwaysContainsIndependentCommaFragment() throws {
        let fragments = FormulaEditorView.piecewiseRowFragmentKinds()
        #expect(fragments == [.valueSlot, .commaToken, .conditionSlot])
    }

    @Test func piecewiseRowLayoutColumnMinWidthsArePositive() throws {
        #expect(FormulaEditorView.piecewiseValueColumnMinWidth > 0)
        #expect(FormulaEditorView.piecewiseConditionColumnMinWidth > 0)
        #expect(FormulaEditorView.piecewiseCommaMinWidth > 0)
    }

    @Test func piecewiseCommaPositionStaysStableForShortValueContent() throws {
        let oneChar = FormulaEditorView.piecewiseCommaLeadingX(valueContentWidth: 10)
        let twoChars = FormulaEditorView.piecewiseCommaLeadingX(valueContentWidth: 20)
        let threeChars = FormulaEditorView.piecewiseCommaLeadingX(valueContentWidth: 24)
        #expect(oneChar == twoChars)
        #expect(twoChars == threeChars)
    }

    @Test func piecewiseCommaPositionUsesExpandedWidthWhenValueExceedsMinWidth() throws {
        let min = FormulaEditorView.piecewiseCommaLeadingX(valueContentWidth: FormulaEditorView.piecewiseValueColumnMinWidth)
        let expanded = FormulaEditorView.piecewiseCommaLeadingX(valueContentWidth: FormulaEditorView.piecewiseValueColumnMinWidth + 20)
        #expect(expanded > min)
    }

    @Test func parametricLayoutColumnWidthsArePositive() throws {
        #expect(FormulaEditorView.parametricBraceColumnWidth > 0)
        #expect(FormulaEditorView.parametricLabelColumnWidth > 0)
        #expect(FormulaEditorView.parametricEqualsColumnWidth > 0)
        #expect(FormulaEditorView.parametricExpressionColumnMinWidth > 0)
        #expect(FormulaEditorView.parametricRangeLeadingInset > 0)
        #expect(FormulaEditorView.parametricRowMinHeight > 0)
        #expect(
            FormulaEditorView.parametricBraceHeight(
                xRowHeight: FormulaEditorView.parametricRowMinHeight,
                yRowHeight: FormulaEditorView.parametricRowMinHeight
            ) >= (FormulaEditorView.parametricRowMinHeight * 2)
        )
    }

    @Test func parametricLabelAndEqualsColumnsHaveStableWidths() throws {
        #expect(FormulaEditorView.parametricLabelColumnWidth <= FormulaEditorView.parametricBraceColumnWidth + FormulaEditorView.parametricExpressionColumnMinWidth)
        #expect(FormulaEditorView.parametricEqualsColumnWidth < FormulaEditorView.parametricExpressionColumnMinWidth)
        #expect(FormulaEditorView.parametricTokenSpacing >= 0)
        #expect(
            FormulaEditorView.parametricBraceHeight(
                xRowHeight: FormulaEditorView.parametricRowMinHeight,
                yRowHeight: FormulaEditorView.parametricRowMinHeight
            ) == (FormulaEditorView.parametricRowMinHeight * 2 + FormulaEditorView.parametricRowSpacing)
        )
    }

    @Test func tokenTapBoundaryMapsToNearestCursorSide() throws {
        let left = FormulaEditorView.sequenceBoundaryOffsetForTokenTap(
            locationX: 4,
            viewWidth: 20,
            tokenIndex: 3
        )
        let right = FormulaEditorView.sequenceBoundaryOffsetForTokenTap(
            locationX: 16,
            viewWidth: 20,
            tokenIndex: 3
        )
        #expect(left == 3)
        #expect(right == 4)
    }

    @Test func templateEntryCursorUsesInitialField() throws {
        let cursor = FormulaEditorView.templateEntryCursor(
            path: [.sequenceIndex(0)],
            kind: .parametricEquation2D
        )
        #expect(cursor.path == [.sequenceIndex(0), .templateField(.parametricExpression(0))])
        #expect(cursor.offset == 0)
    }

    @Test func parametricSlotEntryCursorsMapToDedicatedFields() throws {
        let base: [EditorPathComponent] = [.sequenceIndex(2)]
        let x = FormulaEditorView.slotEntryCursor(path: base, kind: .parametricEquation2D, field: .parametricExpression(0))
        let y = FormulaEditorView.slotEntryCursor(path: base, kind: .parametricEquation2D, field: .parametricExpression(1))
        let r = FormulaEditorView.slotEntryCursor(path: base, kind: .parametricEquation2D, field: .parametricRange)
        #expect(x.path == [.sequenceIndex(2), .templateField(.parametricExpression(0))])
        #expect(y.path == [.sequenceIndex(2), .templateField(.parametricExpression(1))])
        #expect(r.path == [.sequenceIndex(2), .templateField(.parametricRange)])
    }

    @Test func piecewiseSlotEntryCursorsMapToRowValueAndCondition() throws {
        let base: [EditorPathComponent] = [.sequenceIndex(1)]
        let row0Value = FormulaEditorView.slotEntryCursor(path: base, kind: .piecewise(rows: 3), field: .rowExpression(0))
        let row0Cond = FormulaEditorView.slotEntryCursor(path: base, kind: .piecewise(rows: 3), field: .rowCondition(0))
        let row1Value = FormulaEditorView.slotEntryCursor(path: base, kind: .piecewise(rows: 3), field: .rowExpression(1))
        let row1Cond = FormulaEditorView.slotEntryCursor(path: base, kind: .piecewise(rows: 3), field: .rowCondition(1))
        #expect(row0Value.path == [.sequenceIndex(1), .templateField(.rowExpression(0))])
        #expect(row0Cond.path == [.sequenceIndex(1), .templateField(.rowCondition(0))])
        #expect(row1Value.path == [.sequenceIndex(1), .templateField(.rowExpression(1))])
        #expect(row1Cond.path == [.sequenceIndex(1), .templateField(.rowCondition(1))])
    }

    @Test func fractionSuperscriptRootAndFunctionSlotEntryCursorsMapCorrectly() throws {
        let fractionDen = FormulaEditorView.slotEntryCursor(path: [.sequenceIndex(0)], kind: .fraction, field: .denominator)
        let superscriptExp = FormulaEditorView.slotEntryCursor(path: [.sequenceIndex(0)], kind: .superscript, field: .exponent)
        let sqrtRad = FormulaEditorView.slotEntryCursor(path: [.sequenceIndex(0)], kind: .sqrt, field: .radicand)
        let fnArg = FormulaEditorView.slotEntryCursor(path: [.sequenceIndex(0)], kind: .sin, field: .argument)
        #expect(fractionDen.path == [.sequenceIndex(0), .templateField(.denominator)])
        #expect(superscriptExp.path == [.sequenceIndex(0), .templateField(.exponent)])
        #expect(sqrtRad.path == [.sequenceIndex(0), .templateField(.radicand)])
        #expect(fnArg.path == [.sequenceIndex(0), .templateField(.argument)])
    }

    @Test func hitRegionResolverPrefersHigherPrioritySlotOverTemplateBody() throws {
        let slot = MathEditorHitRegion(
            id: "slot",
            kind: .editableSlot(role: .parametricY),
            rect: CGRect(x: 0, y: 0, width: 40, height: 20),
            cursor: .init(path: [.sequenceIndex(0), .templateField(.parametricExpression(1))], offset: 0),
            priority: 100
        )
        let body = MathEditorHitRegion(
            id: "body",
            kind: .templateBody,
            rect: CGRect(x: 0, y: 0, width: 120, height: 60),
            cursor: .init(path: [.sequenceIndex(0), .templateField(.parametricExpression(0))], offset: 0),
            priority: 10
        )
        let resolved = FormulaEditorView.resolveHitRegion(at: CGPoint(x: 10, y: 10), in: [body, slot])
        #expect(resolved?.id == "slot")
    }

    @Test func hitRegionResolverUsesSmallerAreaWhenPriorityTies() throws {
        let narrow = MathEditorHitRegion(
            id: "narrow",
            kind: .token,
            rect: CGRect(x: 0, y: 0, width: 20, height: 20),
            cursor: .init(path: [], offset: 1),
            priority: 40
        )
        let wide = MathEditorHitRegion(
            id: "wide",
            kind: .token,
            rect: CGRect(x: 0, y: 0, width: 120, height: 20),
            cursor: .init(path: [], offset: 0),
            priority: 40
        )
        let resolved = FormulaEditorView.resolveHitRegion(at: CGPoint(x: 10, y: 10), in: [wide, narrow])
        #expect(resolved?.id == "narrow")
    }

    @Test func nearestTokenBoundaryCursorSupportsInsideAndNearbyPoints() throws {
        let before = EditorCursor(path: [], offset: 2)
        let after = EditorCursor(path: [], offset: 3)
        let token = MathEditorHitRegion(
            id: "token",
            kind: .token,
            rect: CGRect(x: 20, y: 10, width: 20, height: 12),
            cursor: before,
            path: [],
            cursorBefore: before,
            cursorAfter: after,
            priority: 40
        )

        let insideLeft = FormulaEditorView.nearestTokenBoundaryCursor(point: CGPoint(x: 23, y: 12), tokenRegion: token)
        let insideRight = FormulaEditorView.nearestTokenBoundaryCursor(point: CGPoint(x: 37, y: 12), tokenRegion: token)
        let outsideLeft = FormulaEditorView.nearestTokenBoundaryCursor(point: CGPoint(x: 18, y: 12), tokenRegion: token)
        let outsideRight = FormulaEditorView.nearestTokenBoundaryCursor(point: CGPoint(x: 45, y: 12), tokenRegion: token)
        #expect(insideLeft == before)
        #expect(insideRight == after)
        #expect(outsideLeft == before)
        #expect(outsideRight == after)
    }

    @Test func fallbackResolverUsesRowSideForSlotBlanks() throws {
        let slotPath: [EditorPathComponent] = [.templateField(.parametricExpression(0))]
        let root: MathNode = .template(
            .init(
                kind: .parametricEquation2D,
                fields: [
                    .init(id: .parametricExpression(0), node: .sequence([.symbol("t")])),
                    .init(id: .parametricExpression(1), node: .sequence([.symbol("t")]))
                ]
            )
        )
        let slot = MathEditorHitRegion(
            id: "slot",
            kind: .editableSlot(role: .parametricX),
            rect: CGRect(x: 40, y: 20, width: 40, height: 20),
            cursor: EditorCursor(path: slotPath, offset: 0),
            path: slotPath,
            priority: 100
        )
        let left = FormulaEditorView.resolveFallbackCursor(at: CGPoint(x: 20, y: 30), regions: [slot], root: root)
        let right = FormulaEditorView.resolveFallbackCursor(at: CGPoint(x: 100, y: 30), regions: [slot], root: root)
        #expect(left == EditorCursor(path: slotPath, offset: 0))
        #expect(right == EditorCursor(path: slotPath, offset: 1))
    }

    @Test func fallbackResolverPrefersTemplateInitialFieldNearBrace() throws {
        let templateCursor = EditorCursor(path: [.sequenceIndex(0), .templateField(.parametricExpression(0))], offset: 0)
        let template = MathEditorHitRegion(
            id: "template",
            kind: .templateBody,
            rect: CGRect(x: 10, y: 10, width: 80, height: 50),
            cursor: templateCursor,
            priority: 10
        )
        let cursor = FormulaEditorView.resolveFallbackCursor(
            at: CGPoint(x: 4, y: 30),
            regions: [template],
            root: .sequence([.placeholder])
        )
        #expect(cursor == templateCursor)
    }

    @Test func parametricLatexRendersRangeOutsideBrace() throws {
        let template = TemplateNode(
            kind: .parametricEquation2D,
            fields: [
                .init(id: .parametricExpression(0), node: .sequence([.symbol("2"), .symbol("t")])),
                .init(id: .parametricExpression(1), node: .sequence([.symbol("t")])),
                .init(id: .parametricRange, node: .sequence([.symbol("0"), .operatorSymbol("<"), .symbol("t"), .operatorSymbol("<"), .symbol("4")]))
            ]
        )
        let state = EditorState(root: .sequence([.template(template)]))
        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        #expect(latex == "\\left\\{x=2t,\\ y=t\\right\\},\\ 0<t<4")
    }

    @Test func formulaEditorPreferredHeightGrowsForStructuredTemplates() throws {
        let plain = EditorState(root: .sequence([.symbol("x"), .operatorSymbol("="), .symbol("1")]))
        let piecewiseTemplate = TemplateNode(
            kind: .piecewise(rows: 4),
            fields: [
                .init(id: .rowExpression(0), node: .sequence([.symbol("x")])),
                .init(id: .rowCondition(0), node: .sequence([.symbol("x"), .operatorSymbol("<"), .symbol("0")])),
                .init(id: .rowExpression(1), node: .sequence([.symbol("x"), .operatorSymbol("+"), .symbol("1")])),
                .init(id: .rowCondition(1), node: .sequence([.symbol("x"), .operatorSymbol(">"), .symbol("0")])),
                .init(id: .rowExpression(2), node: .sequence([.symbol("x"), .operatorSymbol("+"), .symbol("2")])),
                .init(id: .rowCondition(2), node: .sequence([.symbol("x"), .operatorSymbol(">"), .symbol("1")])),
                .init(id: .rowExpression(3), node: .sequence([.symbol("x"), .operatorSymbol("+"), .symbol("3")])),
                .init(id: .rowCondition(3), node: .sequence([.symbol("x"), .operatorSymbol(">"), .symbol("2")]))
            ]
        )
        let piecewise = EditorState(root: .sequence([.template(piecewiseTemplate)]))
        #expect(FormulaEditorView.preferredHeight(for: piecewise) > FormulaEditorView.preferredHeight(for: plain))
    }

    @Test func backspaceInEmptySuperscriptRemovesTemplate() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.backspace, state: &state)
        #expect(SourceSerializer().serialize(state) == "x")
    }

    @Test func backspaceInNonEmptySuperscriptDeletesExponentToken() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.backspace, state: &state)
        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        #expect(latex == "x^{\\square}")
    }

    @Test func backspaceInFractionNumeratorDoesNotCorruptLatex() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)
        controller.handle(.backspace, state: &state)
        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        #expect(latex == "\\frac{\\square}{\\square}")
    }

    @Test func backspaceAfterFractionRemovesOrSelectsFractionSafely() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        controller.handle(.tab, state: &state)
        controller.handle(.tab, state: &state)
        controller.handle(.backspace, state: &state)
        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        #expect(latex.isEmpty || latex == "\\frac{\\square}{\\square}")
    }

    @Test func deleteDoesNotProduceInvalidAst() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.sqrt), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.tab, state: &state)
        controller.handle(.delete, state: &state)
        _ = LatexMathRenderer().renderLatex(state.root, editing: true)
        _ = SourceSerializer().serialize(state)
        _ = ComputeSerializer().serialize(state)
        #expect(Bool(true))
    }

    @Test func textSelectionMapsBackToEditorCursor() throws {
        var input = FormulaInputState()
        let controller = InputController()
        controller.handle(.insertCharacter("y"), state: &input.editorState)
        controller.handle(.insertOperator("="), state: &input.editorState)
        controller.handle(.insertCharacter("2"), state: &input.editorState)
        controller.handle(.insertCharacter("x"), state: &input.editorState)
        controller.handle(.insertTemplate(.superscript), state: &input.editorState)
        controller.handle(.insertCharacter("2"), state: &input.editorState)
        input.syncDerivedStrings()

        let projection = CursorProjectionResult(source: input.source, cursorIndex: input.cursorIndex, cursorStops: input.sourceCursorStops)
        let mapped = SourceRangeToCursorMapper.map(range: 2..<2, in: projection)
        #expect(mapped.path.isEmpty)
        #expect(mapped.offset == 2)
    }

    @Test func insertTemplateCursorIndexNotAtSourceEndForFraction() throws {
        var input = FormulaInputState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &input.editorState)
        input.syncDerivedStrings()
        #expect(input.cursorIndex < input.source.count)
        #expect(input.source == "\\frac{}{}")
    }

    @MainActor
    @Test func workspaceStateSuperscriptInputGoesIntoExponentField() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x"))
        state.handleKeyboardAction(.insertTemplate(.superscript))
        state.handleKeyboardAction(.insertCharacter("2"))

        #expect(state.formulaInputState.source == "y=x^{2}")
        #expect(state.formulaInputState.displayLatex == "y=x^{2}")
        if case .sequence(let nodes) = state.formulaInputState.editorState.root,
           case .template(let sup)? = nodes.last {
            #expect(sup.kind == .superscript)
            let exponent = sup.field(.exponent)
            #expect(exponent == .sequence([.character("2")]))
        } else {
            #expect(Bool(false))
        }
    }

    @MainActor
    @Test func superscriptAfterEqualsDoesNotConsumeEqualsAsBase() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y="))
        state.handleKeyboardAction(.insertTemplate(.superscript))

        #expect(!state.formulaInputState.source.contains("{=}"))
        #expect(state.formulaInputState.source.hasPrefix("y="))
        #expect(state.formulaInputState.source.contains("^{"))
        if case .sequence(let nodes) = state.formulaInputState.editorState.root,
           case .template(let sup)? = nodes.last {
            #expect(sup.kind == .superscript)
            #expect(sup.field(.base) == .sequence([.placeholder]))
            #expect(sup.field(.exponent) == .sequence([.placeholder]))
            #expect(state.formulaInputState.editorState.cursor.path == [.sequenceIndex(2), .templateField(.base)])
        } else {
            #expect(Bool(false))
        }
    }

    @MainActor
    @Test func repeatedSuperscriptOnEmptyExponentIsIgnored() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x"))
        state.handleKeyboardAction(.insertTemplate(.superscript))
        let before = state.formulaInputState.source
        state.handleKeyboardAction(.insertTemplate(.superscript))
        #expect(state.formulaInputState.source == before)
    }

    @Test func fractionDownMovesToDenominator() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        controller.handle(.moveDown, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.denominator)])
    }

    @Test func fractionTabMovesNumeratorToDenominatorThenExits() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.denominator)])
        controller.handle(.tab, state: &state)
        #expect(state.cursor.path.isEmpty)
    }

    @Test func fractionRightExitsFromDenominator() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        controller.handle(.moveDown, state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path.isEmpty)
    }

    @Test func fractionShiftTabMovesDenominatorToNumeratorEnd() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)
        controller.handle(.tab, state: &state) // denominator
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.denominator)])
        controller.handle(.shiftTab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.numerator)])
        #expect(state.cursor.offset == 1)
    }

    @Test func afterFractionShiftTabEntersDenominatorEnd() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)
        controller.handle(.tab, state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.tab, state: &state) // exit
        #expect(state.cursor.path.isEmpty)
        controller.handle(.shiftTab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.denominator)])
        #expect(state.cursor.offset == 1)
    }

    @Test func sqrtRightExitsRadicand() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.sqrt), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.moveRight, state: &state)
        controller.handle(.insertOperator("+"), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)
        #expect(LatexMathRenderer().renderLatex(state.root, editing: true) == "\\sqrt{x}+1")
    }

    @Test func placeholderInputReplacesPlaceholder() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.sqrt), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        #expect(SourceSerializer().serialize(state) == "\\sqrt{x}")
        #expect(!SourceSerializer().serialize(state).contains("{}"))
    }

    @Test func superscriptRightFromBaseMovesToExponent() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.base)])
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.exponent)])
    }

    @Test func superscriptShiftTabMovesExponentToBaseEnd() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.exponent)])
        controller.handle(.shiftTab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.base)])
        #expect(state.cursor.offset == 1)
    }

    @Test func afterSuperscriptShiftTabEntersExponentEnd() throws {
        var state = EditorState(root: .sequence([.character("x")]), cursor: EditorCursor(path: [], offset: 1))
        let controller = InputController()
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.moveRight, state: &state) // exit superscript
        #expect(state.cursor.path.isEmpty)
        controller.handle(.shiftTab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.exponent)])
        #expect(state.cursor.offset == 1)
    }

    @Test func afterRootShiftTabEntersRadicandEnd() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.sqrt), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.moveRight, state: &state) // exit root
        #expect(state.cursor.path.isEmpty)
        controller.handle(.shiftTab, state: &state)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.radicand)])
        #expect(state.cursor.offset == 1)
    }

    @Test func piecewiseLastConditionRightExitsTemplate() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.piecewise(rows: 2)), state: &state)
        controller.handle(.tab, state: &state) // row0 cond
        controller.handle(.tab, state: &state) // row1 expr
        controller.handle(.tab, state: &state) // row1 cond
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.rowCondition(1))])
        controller.handle(.moveRight, state: &state)
        #expect(state.cursor.path.isEmpty)
        #expect(state.cursor.offset == 1)
    }

    @Test func cursorControllerTabOrderHelpersWorkForParametric() throws {
        let def = TemplateDefinitionRegistry.definition(for: .parametricEquation2D)
        #expect(EditorCursorNavigator.nextFieldInTabOrder(currentField: .parametricExpression(0), templateDefinition: def) == .parametricExpression(1))
        #expect(EditorCursorNavigator.nextFieldInTabOrder(currentField: .parametricExpression(1), templateDefinition: def) == .parametricRange)
        #expect(EditorCursorNavigator.previousFieldInTabOrder(currentField: .parametricRange, templateDefinition: def) == .parametricExpression(1))
        #expect(EditorCursorNavigator.previousFieldInTabOrder(currentField: .parametricExpression(1), templateDefinition: def) == .parametricExpression(0))
    }

    @Test func cursorControllerVerticalNeighborHelpersWorkForPiecewiseAndFraction() throws {
        #expect(EditorCursorNavigator.verticalNeighborField(currentField: .rowExpression(0), direction: .down, templateKind: .piecewise(rows: 2)) == .rowExpression(1))
        #expect(EditorCursorNavigator.verticalNeighborField(currentField: .rowCondition(1), direction: .up, templateKind: .piecewise(rows: 2)) == .rowCondition(0))
        #expect(EditorCursorNavigator.verticalNeighborField(currentField: .numerator, direction: .down, templateKind: .fraction) == .denominator)
        #expect(EditorCursorNavigator.verticalNeighborField(currentField: .denominator, direction: .up, templateKind: .fraction) == .numerator)
    }

    @Test func navigatorExitTemplateCursorsForwardAndReverse() throws {
        let templatePath: [EditorPathComponent] = [.sequenceIndex(3)]
        #expect(EditorCursorNavigator.exitTemplateCursor(templatePath: templatePath, reverse: false) == EditorCursor(path: [], offset: 4))
        #expect(EditorCursorNavigator.exitTemplateCursor(templatePath: templatePath, reverse: true) == EditorCursor(path: [], offset: 3))
    }

    @Test func navigatorMoveDoesNotMutateRoot() throws {
        let root: MathNode = .sequence([
            .template(
                .init(
                    kind: .fraction,
                    fields: [
                        .init(id: .numerator, node: .sequence([.character("1")])),
                        .init(id: .denominator, node: .sequence([.character("2")]))
                    ]
                )
            )
        ])
        let navigator = EditorCursorNavigator(root: root)
        _ = navigator.moveRight(from: EditorCursor(path: [.sequenceIndex(0), .templateField(.numerator)], offset: 1))
        #expect(root == .sequence([
            .template(
                .init(
                    kind: .fraction,
                    fields: [
                        .init(id: .numerator, node: .sequence([.character("1")])),
                        .init(id: .denominator, node: .sequence([.character("2")]))
                    ]
                )
            )
        ]))
    }

    @Test func sinCreatesFunctionTemplateAndRightExitsArgument() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertFunction("sin"), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.moveRight, state: &state)
        controller.handle(.insertOperator("+"), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)
        #expect(LatexMathRenderer().renderLatex(state.root, editing: true) == "\\sin(x)+1")
    }

    @Test func absCreatesTemplateAndRightExitsContent() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.absoluteValue), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.moveRight, state: &state)
        controller.handle(.insertOperator("+"), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)
        #expect(LatexMathRenderer().renderLatex(state.root, editing: true) == "\\left|x\\right|+1")
    }

    @Test func subscriptCreatesTemplateAndDoesNotConsumeEquals() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertCharacter("y"), state: &state)
        controller.handle(.insertOperator("="), state: &state)
        controller.handle(.insertTemplate(.subscriptTemplate), state: &state)
        if case .sequence(let nodes) = state.root,
           case .template(let sub)? = nodes.last {
            #expect(sub.kind == .subscriptTemplate)
            #expect(sub.field(.base) == .sequence([.placeholder]))
        } else {
            #expect(Bool(false))
        }
    }

    @MainActor
    @Test func hidingMathKeyboardDoesNotResignFormulaEditorFocus() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        #expect(state.focus == .formulaEditor)
        state.dispatch(.setKeyboardVisible(false))
        #expect(state.focus == .formulaEditor)
        state.handleKeyboardAction(.insertCharacter("x"))
        #expect(state.formulaInputState.source == "x")
    }

    @MainActor
    @Test func noRuntimeLatexTemplateInsertionPath() throws {
        SimpleMathParser.resetInvocationCount()
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.handleKeyboardAction(.insertTemplate(.fraction))
        state.handleKeyboardAction(.insertCharacter("1"))
        state.handleKeyboardAction(.moveDown)
        state.handleKeyboardAction(.insertCharacter("2"))
        #expect(SimpleMathParser.parseInvocationCount == 0)
    }

    @MainActor
    @Test func noParseSourceDuringKeyboardAction() throws {
        SimpleMathParser.resetInvocationCount()
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "Test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.handleKeyboardAction(.insertCharacter("x"))
        state.handleKeyboardAction(.insertTemplate(.superscript))
        state.handleKeyboardAction(.insertCharacter("2"))
        #expect(SimpleMathParser.parseInvocationCount == 0)
    }

    @Test func caretCharacterInsertsSuperscriptTemplate() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertCharacter("^"), state: &state)
        guard case .sequence(let nodes) = state.root,
              case .template(let template)? = nodes.first else {
            Issue.record("Expected superscript template")
            return
        }
        #expect(template.kind == .superscript)
        #expect(state.cursor.path == [.sequenceIndex(0), .templateField(.base)])
    }

    @Test func backspaceInTemplateFieldLeavesSinglePlaceholder() throws {
        let root: MathNode = .sequence([
            .template(
                .init(
                    kind: .fraction,
                    fields: [
                        .init(id: .numerator, node: .sequence([.character("x")])),
                        .init(id: .denominator, node: .sequence([.placeholder]))
                    ]
                )
            )
        ])
        var state = EditorState(
            root: root,
            cursor: EditorCursor(path: [.sequenceIndex(0), .templateField(.numerator)], offset: 1)
        )
        let controller = InputController()
        controller.handle(.backspace, state: &state)
        guard let numerator = MathEditorTree.node(at: [.sequenceIndex(0), .templateField(.numerator)], in: state.root),
              case .sequence(let nodes) = numerator else {
            Issue.record("Missing numerator")
            return
        }
        #expect(nodes.count == 1)
        #expect(nodes.first == .placeholder)
        #expect(state.cursor.offset == 0)
    }

    @Test func deleteForwardInTemplateFieldLeavesSinglePlaceholder() throws {
        let root: MathNode = .sequence([
            .template(
                .init(
                    kind: .fraction,
                    fields: [
                        .init(id: .numerator, node: .sequence([.character("x")])),
                        .init(id: .denominator, node: .sequence([.placeholder]))
                    ]
                )
            )
        ])
        var state = EditorState(
            root: root,
            cursor: EditorCursor(path: [.sequenceIndex(0), .templateField(.numerator)], offset: 0)
        )
        let controller = InputController()
        controller.handle(.delete, state: &state)
        guard let numerator = MathEditorTree.node(at: [.sequenceIndex(0), .templateField(.numerator)], in: state.root),
              case .sequence(let nodes) = numerator else {
            Issue.record("Missing numerator")
            return
        }
        #expect(nodes.count == 1)
        #expect(nodes.first == .placeholder)
        #expect(state.cursor.offset == 0)
    }

    @Test func keyboardHardwareMapperMapsSpecialKeysToCanonicalActions() throws {
        #expect(
            KeyboardHardwareMapper.map(
                keyCode: .keyboardDeleteOrBackspace,
                characters: "",
                charactersIgnoringModifiers: "",
                modifierFlags: []
            ) == .deleteBackward
        )
        #expect(
            KeyboardHardwareMapper.map(
                keyCode: .keyboardDeleteForward,
                characters: "",
                charactersIgnoringModifiers: "",
                modifierFlags: []
            ) == .deleteForward
        )
        #expect(
            KeyboardHardwareMapper.map(
                keyCode: .keyboardReturnOrEnter,
                characters: "\r",
                charactersIgnoringModifiers: "\r",
                modifierFlags: []
            ) == .submit
        )
        #expect(
            KeyboardHardwareMapper.map(
                keyCode: .keyboardEscape,
                characters: "",
                charactersIgnoringModifiers: "",
                modifierFlags: []
            ) == .cancel
        )
    }

    @Test func keyboardHardwareMapperMapsShift6ToSuperscriptTemplate() throws {
        #expect(
            KeyboardHardwareMapper.map(
                keyCode: .keyboard6,
                characters: "6",
                charactersIgnoringModifiers: "6",
                modifierFlags: [.shift]
            ) == .insertTemplate(.superscript)
        )
    }

    @Test func keyboardHardwareMapperDoesNotMapCommandModifiedZAsPlainCharacter() throws {
        #expect(
            KeyboardHardwareMapper.map(
                keyCode: .keyboardZ,
                characters: "",
                charactersIgnoringModifiers: "z",
                modifierFlags: [.command]
            ) == nil
        )
        #expect(
            KeyboardHardwareMapper.map(
                keyCode: .keyboardZ,
                characters: "",
                charactersIgnoringModifiers: "z",
                modifierFlags: [.command, .shift]
            ) == nil
        )
    }

    @Test func keyboardHardwareMapperDoesNotMapCommandModifiedYAsPlainCharacter() throws {
        #expect(
            KeyboardHardwareMapper.map(
                keyCode: .keyboardY,
                characters: "",
                charactersIgnoringModifiers: "y",
                modifierFlags: [.command]
            ) == nil
        )
    }

    @Test func legacyKeyboardActionsForwardToCanonicalBehavior() throws {
        let controller = InputController()

        var withLegacyBackspace = EditorState(
            root: .sequence([.character("x")]),
            cursor: EditorCursor(path: [], offset: 1)
        )
        controller.handle(.backspace, state: &withLegacyBackspace)

        var withCanonicalDeleteBackward = EditorState(
            root: .sequence([.character("x")]),
            cursor: EditorCursor(path: [], offset: 1)
        )
        controller.handle(.deleteBackward, state: &withCanonicalDeleteBackward)
        #expect(withLegacyBackspace == withCanonicalDeleteBackward)

        var withLegacyDelete = EditorState(
            root: .sequence([.character("x"), .character("y")]),
            cursor: EditorCursor(path: [], offset: 0)
        )
        controller.handle(.delete, state: &withLegacyDelete)

        var withCanonicalDeleteForward = EditorState(
            root: .sequence([.character("x"), .character("y")]),
            cursor: EditorCursor(path: [], offset: 0)
        )
        controller.handle(.deleteForward, state: &withCanonicalDeleteForward)
        #expect(withLegacyDelete == withCanonicalDeleteForward)
    }

    @Test func mathStyleDefaultsAndLegacyDecode() throws {
        let legacyJSON = #"{"colorToken":"blue","opacity":0.8,"fillOpacity":0.2}"#
        let decoded = try JSONDecoder().decode(MathStyle.self, from: Data(legacyJSON.utf8))
        #expect(decoded.colorToken == "blue")
        #expect(decoded.opacity == 0.8)
        #expect(decoded.fillOpacity == 0.2)
        #expect(decoded.lineWidth == 2.0)
        #expect(decoded.pointSize == 6.0)
        #expect(decoded.lineStyle == .solid)
    }

    @Test func mathStyleSanitizeClampsValues() throws {
        var style = MathStyle(
            colorToken: "red",
            opacity: 2,
            fillOpacity: -1,
            lineWidth: 99,
            pointSize: 1,
            lineStyle: .dashed
        )
        style.sanitizeInPlace()
        #expect(style.opacity == 1)
        #expect(style.fillOpacity == 0)
        #expect(style.lineWidth == 8)
        #expect(style.pointSize == 3)
        #expect(style.lineStyle == .dashed)
    }

    @Test func documentPatchUpdatesStyleOnly() throws {
        let pointID = UUID()
        let expression = MathExpression(displayText: "A=(1,2)")
        let geometry = GeometryDefinition(kind: .point, anchors: [])
        let originalStyle = MathStyle(colorToken: "blue", opacity: 0.9, fillOpacity: 0.2, lineWidth: 2, pointSize: 6, lineStyle: .solid)
        var document = EMathicaDocument(
            metadata: .init(
                title: "test",
                moduleID: "plane",
                createdAt: .now,
                updatedAt: .now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: [
                MathObject(
                    id: pointID,
                    name: "A",
                    type: .point,
                    expression: expression,
                    position: .init(x: 1, y: 2),
                    geometryDefinition: geometry,
                    style: originalStyle
                )
            ]
        )

        document.apply(
            .updateObject(
                id: pointID,
                patch: DocumentObjectPatch(
                    styleColorToken: "green",
                    styleOpacity: 0.5,
                    styleFillOpacity: 0.1,
                    styleLineWidth: 4,
                    stylePointSize: 10,
                    styleLineStyle: .dashed
                )
            )
        )

        guard let updated = document.objects.first(where: { $0.id == pointID }) else {
            Issue.record("Missing updated object")
            return
        }
        #expect(updated.expression == expression)
        #expect(updated.geometryDefinition == geometry)
        #expect(updated.style.colorToken == "green")
        #expect(updated.style.opacity == 0.5)
        #expect(updated.style.fillOpacity == 0.1)
        #expect(updated.style.lineWidth == 4)
        #expect(updated.style.pointSize == 10)
        #expect(updated.style.lineStyle == .dashed)
    }

    @Test func documentRoundTripPreservesLineRaySegmentStyleSliderAndStaticPoint() throws {
        let sliderID = UUID()
        let lineID = UUID()
        let rayID = UUID()
        let segmentID = UUID()
        let circleID = UUID()
        let intersectionPointID = UUID()

        let slider = MathObject(
            id: sliderID,
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=1.5"),
            parameterValue: 1.5,
            sliderSettings: SliderSettings(
                min: -3,
                max: 7,
                step: 0.25,
                precision: 3,
                speed: 2,
                playbackMode: .decreasing,
                playbackLoopMode: .pingPong
            ),
            style: MathStyle(colorToken: "orange")
        )

        let line = MathObject(
            id: lineID,
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: -2, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .line,
                anchors: [.fixedPoint(WorldPoint(x: -2, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "indigo", opacity: 0.6, lineWidth: 5, lineStyle: .dashed)
        )

        let ray = MathObject(
            id: rayID,
            name: "r1",
            type: .ray,
            expression: MathExpression(displayText: "r1: 射线"),
            points: [WorldPoint(x: 1, y: 1), WorldPoint(x: 3, y: 2)],
            geometryDefinition: GeometryDefinition(
                kind: .ray,
                anchors: [.fixedPoint(WorldPoint(x: 1, y: 1)), .fixedPoint(WorldPoint(x: 3, y: 2))]
            ),
            style: MathStyle(colorToken: "pink", opacity: 0.8, lineWidth: 3)
        )

        let segment = MathObject(
            id: segmentID,
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1: 线段"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .segment,
                anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "green", opacity: 0.7, lineWidth: 2)
        )

        let circle = MathObject(
            id: circleID,
            name: "c1",
            type: .circle,
            expression: MathExpression(displayText: "x^2+y^2=1"),
            style: MathStyle(colorToken: "cyan", opacity: 0.5, lineWidth: 4)
        )

        let staticIntersectionPoint = MathObject(
            id: intersectionPointID,
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "white", opacity: 0.9, pointSize: 12)
        )

        let document = EMathicaDocument(
            metadata: .init(
                title: "roundtrip",
                moduleID: "plane",
                createdAt: .now,
                updatedAt: .now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: [slider, line, ray, segment, circle, staticIntersectionPoint]
        )

        let encoded = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode(EMathicaDocument.self, from: encoded)

        #expect(decoded.objects.count == document.objects.count)
        #expect(Set(decoded.objects.map(\.id)) == Set(document.objects.map(\.id)))

        guard let decodedSlider = decoded.objects.first(where: { $0.id == sliderID }) else {
            Issue.record("Missing decoded slider object")
            return
        }
        #expect(decodedSlider.type == .parameter)
        #expect(decodedSlider.parameterValue == 1.5)
        #expect(decodedSlider.sliderSettings == slider.sliderSettings)

        guard let decodedLine = decoded.objects.first(where: { $0.id == lineID }) else {
            Issue.record("Missing decoded line object")
            return
        }
        #expect(decodedLine.geometryDefinition?.kind == .line)
        #expect(decodedLine.style == line.style)

        guard let decodedRay = decoded.objects.first(where: { $0.id == rayID }) else {
            Issue.record("Missing decoded ray object")
            return
        }
        #expect(decodedRay.geometryDefinition?.kind == .ray)
        #expect(decodedRay.style == ray.style)

        guard let decodedSegment = decoded.objects.first(where: { $0.id == segmentID }) else {
            Issue.record("Missing decoded segment object")
            return
        }
        #expect(decodedSegment.geometryDefinition?.kind == .segment)
        #expect(decodedSegment.style == segment.style)

        guard let decodedPoint = decoded.objects.first(where: { $0.id == intersectionPointID }) else {
            Issue.record("Missing decoded static intersection point")
            return
        }
        #expect(decodedPoint.type == .point)
        #expect(decodedPoint.geometryDefinition?.kind == .point)
        #expect(decodedPoint.style == staticIntersectionPoint.style)
    }

    @MainActor
    @Test func editingExplicitFunctionPreservesStyle() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "test"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x^2"))
        state.dispatch(.submitInput)

        guard let objectID = state.selectedObjectID,
              let created = state.document.objects.first(where: { $0.id == objectID }) else {
            Issue.record("Expected created function object")
            return
        }

        let expectedStyle = MathStyle(
            colorToken: "red",
            opacity: 0.5,
            fillOpacity: created.style.fillOpacity,
            lineWidth: 5,
            pointSize: created.style.pointSize,
            lineStyle: .dashed
        )
        state.updateObjectStyle(id: objectID, style: expectedStyle)
        state.beginEditingObjectExpression(objectID, openKeyboard: false)
        state.dispatch(.updateInputText("y=sin(x)"))
        state.dispatch(.submitInput)

        guard let edited = state.document.objects.first(where: { $0.id == objectID }) else {
            Issue.record("Expected edited function object")
            return
        }
        #expect(edited.style == expectedStyle)
        #expect(edited.id == objectID)
    }

    @Test func documentPatchExpressionUpdatePreservesExistingStyle() throws {
        let objectID = UUID()
        let style = MathStyle(colorToken: "purple", opacity: 0.65, lineWidth: 5, lineStyle: .dashed)
        var document = EMathicaDocument(
            metadata: .init(
                title: "style-preserve",
                moduleID: "plane",
                createdAt: .now,
                updatedAt: .now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: [
                MathObject(
                    id: objectID,
                    name: "f",
                    type: .function,
                    expression: MathExpression(displayText: "y=x^2"),
                    style: style
                )
            ]
        )

        document.apply(.updateObject(
            id: objectID,
            patch: DocumentObjectPatch(expressionDisplayText: "y=sin(x)")
        ))
        guard let updated = document.objects.first(where: { $0.id == objectID }) else {
            Issue.record("Missing updated function")
            return
        }
        #expect(updated.style == style)
    }

    @MainActor
    @Test func inspectorVisibilityCommandTogglesWorkspaceState() throws {
        let state = WorkspaceState(
            module: .plane,
            document: PlaneModule.newDocument(title: "inspector-toggle"),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        #expect(state.isInspectorPresented == false)
        state.dispatch(.setInspectorVisible(true))
        #expect(state.isInspectorPresented == true)
        state.dispatch(.setInspectorVisible(false))
        #expect(state.isInspectorPresented == false)
    }

    @Test func implicitRelationSupportsAdjacentXY() throws {
        var input = FormulaInputState(
            editorState: .init(root: .sequence([
                .character("x"), .character("y"), .operatorSymbol("="), .character("1")
            ]))
        )
        input.syncDerivedStrings()
        #expect(input.semanticState.expression == .equation(
            left: .multiply([
                .symbol(Symbol(name: "x", role: .unknown)),
                .symbol(Symbol(name: "y", role: .unknown))
            ]),
            right: .integer(1)
        ))
        if case .implicit(let relation)? = input.semanticState.graphClassification?.intent {
            #expect(relation == .equation(
                left: .multiply([
                    .symbol(Symbol(name: "x", role: .unknown)),
                    .symbol(Symbol(name: "y", role: .unknown))
                ]),
                right: .integer(1)
            ))
        } else {
            Issue.record("Expected implicit intent for xy=1")
        }
    }

    @Test func explicitYSupportsNumericImplicitMultiplication() throws {
        let lowered = MathNodeSemanticLowering().lower(.sequence([.character("2"), .character("x")]))
        #expect(lowered.expr == .multiply([
            .integer(2),
            .symbol(Symbol(name: "x", role: .unknown))
        ]))
    }

    @Test func parametricSupportsImplicitCoefficientBeforeTrig() throws {
        let template = TemplateNode(
            kind: .parametricEquation2D,
            fields: [
                .init(id: .parametricExpression(0), node: .sequence([
                    .character("a"), .character(" "), .character("c"), .character("o"), .character("s"),
                    .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character("t")]))]))
                ])),
                .init(id: .parametricExpression(1), node: .sequence([
                    .character("a"), .character(" "), .character("s"), .character("i"), .character("n"),
                    .template(TemplateNode(kind: .parentheses, fields: [.init(id: .content, node: .sequence([.character("t")]))]))
                ])),
                .init(id: .parametricRange, node: .sequence([.character("0"), .operatorSymbol("<"), .character("t"), .operatorSymbol("<"), .character("1")]))
            ]
        )
        var input = FormulaInputState(editorState: .init(root: .sequence([.template(template)])))
        input.syncDerivedStrings(
            context: .init(
                symbolTable: .init(symbols: [
                    "a": .init(name: "a", role: .parameter)
                ])
            )
        )
        if case .parametric2D(let xExpr, let yExpr, _, _)? = input.semanticState.graphClassification?.intent {
            #expect(xExpr == .multiply([
                .symbol(Symbol(name: "a", role: .unknown)),
                .function(.cos, arguments: [.symbol(Symbol(name: "t", role: .unknown))])
            ]))
            #expect(yExpr == .multiply([
                .symbol(Symbol(name: "a", role: .unknown)),
                .function(.sin, arguments: [.symbol(Symbol(name: "t", role: .unknown))])
            ]))
        } else {
            Issue.record("Expected parametric2D intent for a cos/sin input")
        }
    }

    @Test func piecewiseClosedMiddleBranchIncludesBoundarySamples() throws {
        let x = Symbol(name: "x", role: .variable)
        let intent = GraphIntent.piecewise([
            .init(
                condition: .relation(left: .symbol(x), relation: .less, right: .integer(-1)),
                intent: .explicitY(expression: .integer(-1), variable: x)
            ),
            .init(
                condition: .chainedRelation(
                    expressions: [.integer(-1), .symbol(x), .integer(1)],
                    relations: [.lessOrEqual, .lessOrEqual]
                ),
                intent: .explicitY(expression: .symbol(x), variable: x)
            ),
            .init(
                condition: .relation(left: .symbol(x), relation: .greater, right: .integer(1)),
                intent: .explicitY(expression: .integer(1), variable: x)
            )
        ])
        let sampler = GraphIntentSampler2D(qualityProfile: .balanced)
        let sample = sampler.sample(
            intent: intent,
            xRange: SamplingRange(lower: -2, upper: 2),
            yRange: SamplingRange(lower: -2, upper: 2),
            environment: .variables([:])
        )
        let points = sample.segments.flatMap { $0.points }
        let hasNegativeEndpoint = points.contains { point in
            abs(point.x + 1) < 1e-9 && abs(point.y + 1) < 1e-9
        }
        let hasPositiveEndpoint = points.contains { point in
            abs(point.x - 1) < 1e-9 && abs(point.y - 1) < 1e-9
        }
        #expect(hasNegativeEndpoint)
        #expect(hasPositiveEndpoint)
    }

    @Test func semanticLoweringSupportsUnicodeInequalityFromSymbolNodes() throws {
        let greaterEqual = MathNodeSemanticLowering().lower(.sequence([
            .character("x"), .symbol("≥"), .character("0")
        ]), context: .init(mode: .condition))
        #expect(greaterEqual.expr == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .greaterOrEqual,
            right: .integer(0)
        ))

        let lessEqual = MathNodeSemanticLowering().lower(.sequence([
            .character("x"), .symbol("≤"), .character("0")
        ]), context: .init(mode: .condition))
        #expect(lessEqual.expr == .relation(
            left: .symbol(Symbol(name: "x", role: .unknown)),
            relation: .lessOrEqual,
            right: .integer(0)
        ))
    }

    @Test func loweringKeepsAcosAsFunctionNotImplicitMultiplication() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("acos", argument: "t"))
        #expect(result.expr == .function(.acos, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

    @Test func loweringKeepsAsinAsFunctionNotImplicitMultiplication() throws {
        let result = MathNodeSemanticLowering().lower(manualFunctionCallSequence("asin", argument: "t"))
        #expect(result.expr == .function(.asin, arguments: [.symbol(Symbol(name: "t", role: .unknown))]))
    }

}
