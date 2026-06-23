import Foundation
import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct GraphCoreTests {
    private let classifier = GraphClassifier()
    private let x = Expr.symbol(Symbol(name: "x", role: .variable))
    private let y = Expr.symbol(Symbol(name: "y", role: .variable))
    private let t = Expr.symbol(Symbol(name: "t", role: .parameter))

    @Test func plainExpressionClassifiesAsExplicitY() throws {
        let expr = Expr.power(base: x, exponent: .integer(2))
        let result = classifier.classify(expr)
        #expect(result.intent == .explicitY(expression: expr, variable: Symbol(name: "x", role: .variable)))
    }

    @Test func yEqualsFunctionClassifiesAsExplicitY() throws {
        let expr = Expr.equation(left: y, right: .power(base: x, exponent: .integer(2)))
        let result = classifier.classify(expr)
        #expect(result.intent == .explicitY(expression: .power(base: x, exponent: .integer(2)), variable: Symbol(name: "x", role: .variable)))
    }

    @Test func xEqualsFunctionClassifiesAsExplicitX() throws {
        let expr = Expr.equation(left: x, right: .power(base: y, exponent: .integer(2)))
        let result = classifier.classify(expr)
        #expect(result.intent == .explicitX(expression: .power(base: y, exponent: .integer(2)), variable: Symbol(name: "y", role: .variable)))
    }

    @Test func originCircleEquationClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .add([.power(base: x, exponent: .integer(2)), .power(base: y, exponent: .integer(2))]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .circle(center: .tuple([.integer(0), .integer(0)]), radius: .integer(1)))
    }

    @Test func implicitEquationClassifiesAsImplicit() throws {
        let expr = Expr.equation(
            left: .add([x, y]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .implicit(relation: expr))
    }

    @Test func tupleConstantsClassifiesAsPoint() throws {
        let expr = Expr.tuple([.integer(1), .integer(2)])
        let result = classifier.classify(expr)
        #expect(result.intent == .point(x: .integer(1), y: .integer(2)))
    }

    @Test func tupleFunctionsOfTClassifiesAsPoint() throws {
        let expr = Expr.tuple([
            .function(.cos, arguments: [t]),
            .function(.sin, arguments: [t])
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .point(
            x: .function(.cos, arguments: [t]),
            y: .function(.sin, arguments: [t])
        ))
    }

    @Test func tupleWithSliderDrivenTrigClassifiesAsPoint() throws {
        let a = Expr.symbol(Symbol(name: "a", role: .parameter))
        let expr = Expr.tuple([
            .function(.sin, arguments: [a]),
            .function(.cos, arguments: [a])
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .point(
            x: .function(.sin, arguments: [a]),
            y: .function(.cos, arguments: [a])
        ))
    }

    @Test func piecewiseClassifiesBranches() throws {
        let value = Expr.power(base: x, exponent: .integer(2))
        let expr = Expr.piecewise(branches: [
            PiecewiseBranch(value: value, condition: .relation(left: x, relation: .less, right: .integer(0)))
        ], otherwise: nil)
        let result = classifier.classify(expr)
        #expect(result.intent == .piecewise([
            GraphIntentBranch(
                condition: .relation(left: x, relation: .less, right: .integer(0)),
                intent: .explicitY(expression: value, variable: Symbol(name: "x", role: .variable))
            )
        ]))
    }

    @Test func unknownProducesDiagnostic() throws {
        let expr = Expr.unknown("raw")
        let result = classifier.classify(expr)
        #expect(result.diagnostics.contains { $0.code == .unsupportedExpression })
        #expect(result.intent == .unknown(expr))
    }

    @Test func yEqualsConstantClassifiesAsExplicitY() throws {
        let expr = Expr.equation(left: y, right: .integer(2))
        let result = classifier.classify(expr)
        #expect(result.intent == .explicitY(expression: .integer(2), variable: Symbol(name: "x", role: .variable)))
    }

    @Test func xEqualsConstantClassifiesAsExplicitX() throws {
        let expr = Expr.equation(left: x, right: .integer(2))
        let result = classifier.classify(expr)
        #expect(result.intent == .explicitX(expression: .integer(2), variable: Symbol(name: "y", role: .variable)))
    }

    @Test func originCircleEquationWithSwappedTermsClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .add([.power(base: y, exponent: .integer(2)), .power(base: x, exponent: .integer(2))]),
            right: .integer(4)
        )
        let result = classifier.classify(expr)
        guard case .circle(_, let radius) = result.intent else {
            Issue.record("Expected circle, got \(result.intent)")
            return
        }
        let evaluated = ExprEvaluator().evaluate(radius)
        guard case .value(let r) = evaluated else {
            Issue.record("Expected evaluable radius, got \(evaluated)")
            return
        }
        #expect(abs(r - 2.0) < 1e-9)
    }

    @Test func originCircleEquationWithSwappedSidesClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .integer(4),
            right: .add([.power(base: x, exponent: .integer(2)), .power(base: y, exponent: .integer(2))])
        )
        let result = classifier.classify(expr)
        guard case .circle(_, let radius) = result.intent else {
            Issue.record("Expected circle, got \(result.intent)")
            return
        }
        let evaluated = ExprEvaluator().evaluate(radius)
        guard case .value(let r) = evaluated else {
            Issue.record("Expected evaluable radius, got \(evaluated)")
            return
        }
        #expect(abs(r - 2.0) < 1e-9)
    }

    @Test func originCircleRelationEqualClassifiesAsCircle() throws {
        let expr = Expr.relation(
            left: .add([.power(base: x, exponent: .integer(2)), .power(base: y, exponent: .integer(2))]),
            relation: .equal,
            right: .power(base: .integer(2), exponent: .integer(2))
        )
        let result = classifier.classify(expr)
        guard case .circle(_, let radius) = result.intent else {
            Issue.record("Expected circle, got \(result.intent)")
            return
        }
        let evaluated = ExprEvaluator().evaluate(radius)
        guard case .value(let r) = evaluated else {
            Issue.record("Expected evaluable radius, got \(evaluated)")
            return
        }
        #expect(abs(r - 2.0) < 1e-9)
    }

    @Test func translatedCircleMinusMinusClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2))
            ]),
            right: .integer(9)
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .circle(
            center: .tuple([.integer(1), .integer(2)]),
            radius: .function(.sqrt, arguments: [.integer(9)])
        ))
    }

    @Test func translatedCirclePlusMinusClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: .add([x, .integer(1)]), exponent: .integer(2)),
                .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2))
            ]),
            right: .integer(4)
        )
        let result = classifier.classify(expr)
        guard case .circle(let center, let radius) = result.intent else {
            Issue.record("Expected circle, got \(result.intent)")
            return
        }
        guard case .tuple(let values) = center, values.count == 2 else {
            Issue.record("Expected center tuple, got \(center)")
            return
        }
        let evaluator = ExprEvaluator()
        guard case .value(let cx) = evaluator.evaluate(values[0]),
              case .value(let cy) = evaluator.evaluate(values[1]),
              case .value(let r) = evaluator.evaluate(radius) else {
            Issue.record("Expected evaluable center/radius")
            return
        }
        #expect(abs(cx - (-1.0)) < 1e-9)
        #expect(abs(cy - 2.0) < 1e-9)
        #expect(abs(r - 2.0) < 1e-9)
    }

    @Test func translatedCircleMinusPlusClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                .power(base: .add([y, .integer(2)]), exponent: .integer(2))
            ]),
            right: .integer(4)
        )
        let result = classifier.classify(expr)
        guard case .circle(let center, let radius) = result.intent else {
            Issue.record("Expected circle, got \(result.intent)")
            return
        }
        guard case .tuple(let values) = center, values.count == 2 else {
            Issue.record("Expected center tuple, got \(center)")
            return
        }
        let evaluator = ExprEvaluator()
        guard case .value(let cx) = evaluator.evaluate(values[0]),
              case .value(let cy) = evaluator.evaluate(values[1]),
              case .value(let r) = evaluator.evaluate(radius) else {
            Issue.record("Expected evaluable center/radius")
            return
        }
        #expect(abs(cx - 1.0) < 1e-9)
        #expect(abs(cy - (-2.0)) < 1e-9)
        #expect(abs(r - 2.0) < 1e-9)
    }

    @Test func translatedCircleSwappedOrderClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2))
            ]),
            right: .integer(9)
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .circle(
            center: .tuple([.integer(1), .integer(2)]),
            radius: .function(.sqrt, arguments: [.integer(9)])
        ))
    }

    @Test func translatedCircleSwappedSidesClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .integer(9),
            right: .add([
                .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2))
            ])
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .circle(
            center: .tuple([.integer(1), .integer(2)]),
            radius: .function(.sqrt, arguments: [.integer(9)])
        ))
    }

    @Test func nonPositiveRadiusFallsBackToImplicit() throws {
        let expr = Expr.equation(
            left: .add([.power(base: x, exponent: .integer(2)), .power(base: y, exponent: .integer(2))]),
            right: .integer(-1)
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .implicit(relation: expr))
    }

    @Test func symbolicRadiusFallsBackToImplicit() throws {
        let a = Expr.symbol(Symbol(name: "a", role: .parameter))
        let expr = Expr.equation(
            left: .add([.power(base: x, exponent: .integer(2)), .power(base: y, exponent: .integer(2))]),
            right: a
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .implicit(relation: expr))
    }

    @Test func hyperbolaDoesNotClassifyAsCircle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .negate(.power(base: y, exponent: .integer(2)))
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic hyperbola, got \(result.intent)")
            return
        }
        #expect(info.kind == .hyperbola)
    }

    @Test func shiftedFormWithoutMoveDoesNotClassifyAsCircle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .power(base: y, exponent: .integer(2)),
                .integer(1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        if case .implicit = result.intent {
            #expect(Bool(true))
        } else {
            Issue.record("Expected implicit fallback, got \(result.intent)")
        }
    }

    @Test func standardOriginEllipseClassifiesAsConicEllipse() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(numerator: .power(base: x, exponent: .integer(2)), denominator: .integer(4)),
                .divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9))
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
        #expect(info.orientation == .axisAligned)
        #expect(info.canonicalForm == .originEllipse(
            a: .function(.sqrt, arguments: [.integer(4)]),
            b: .function(.sqrt, arguments: [.integer(9)])
        ))
    }

    @Test func standardOriginEllipseSwappedTermsClassifiesAsConicEllipse() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9)),
                .divide(numerator: .power(base: x, exponent: .integer(2)), denominator: .integer(4))
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
    }

    @Test func standardOriginHyperbolaXClassifiesAsConicHyperbolaX() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(numerator: .power(base: x, exponent: .integer(2)), denominator: .integer(4)),
                .negate(.divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9)))
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .hyperbola)
        #expect(info.canonicalForm == .originHyperbolaX(
            a: .function(.sqrt, arguments: [.integer(4)]),
            b: .function(.sqrt, arguments: [.integer(9)])
        ))
    }

    @Test func standardOriginHyperbolaYClassifiesAsConicHyperbolaY() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9)),
                .negate(.divide(numerator: .power(base: x, exponent: .integer(2)), denominator: .integer(4)))
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .hyperbola)
        #expect(info.canonicalForm == .originHyperbolaY(
            a: .function(.sqrt, arguments: [.integer(4)]),
            b: .function(.sqrt, arguments: [.integer(9)])
        ))
    }

    @Test func standardOriginConicSupportsRelationEqual() throws {
        let expr = Expr.relation(
            left: .add([
                .divide(numerator: .power(base: x, exponent: .integer(2)), denominator: .integer(4)),
                .divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9))
            ]),
            relation: .equal,
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
    }

    @Test func nonPositiveConicDenominatorClassifiesAsHyperbolaInQuadraticPath() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(numerator: .power(base: x, exponent: .integer(2)), denominator: .integer(-4)),
                .divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9))
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic hyperbola, got \(result.intent)")
            return
        }
        #expect(info.kind == .hyperbola)
    }

    @Test func symbolicConicDenominatorFallsBackToImplicit() throws {
        let a = Expr.symbol(Symbol(name: "a", role: .parameter))
        let b = Expr.symbol(Symbol(name: "b", role: .parameter))
        let expr = Expr.equation(
            left: .add([
                .divide(numerator: .power(base: x, exponent: .integer(2)), denominator: a),
                .divide(numerator: .power(base: y, exponent: .integer(2)), denominator: b)
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .implicit(relation: expr))
    }

    @Test func movedOneSideConicFormClassifiesAsConicEllipse() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(numerator: .power(base: x, exponent: .integer(2)), denominator: .integer(4)),
                .divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9)),
                .integer(-1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
    }

    @Test func shiftedConicFormClassifiesAsTranslatedEllipse() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(
                    numerator: .power(base: .add([x, .integer(-1)]), exponent: .integer(2)),
                    denominator: .integer(4)
                ),
                .divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9))
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic ellipse, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
    }

    @Test func translatedCircleWithNonPositiveRadiusFallsBackToImplicit() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2))
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .implicit(relation: expr))
    }

    @Test func translatedCircleWithSymbolicRadiusFallsBackToImplicit() throws {
        let a = Expr.symbol(Symbol(name: "a", role: .parameter))
        let expr = Expr.equation(
            left: .add([
                .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2))
            ]),
            right: a
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .implicit(relation: expr))
    }

    @Test func expandedCircleFormClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .multiply([.integer(-2), x]),
                .power(base: y, exponent: .integer(2)),
                .multiply([.integer(-4), y])
            ]),
            right: .integer(4)
        )
        let result = classifier.classify(expr)
        guard case .circle(let center, let radius) = result.intent else {
            Issue.record("Expected circle, got \(result.intent)")
            return
        }
        guard case .tuple(let values) = center, values.count == 2 else {
            Issue.record("Expected center tuple, got \(center)")
            return
        }
        let evaluator = ExprEvaluator()
        guard case .value(let cx) = evaluator.evaluate(values[0]),
              case .value(let cy) = evaluator.evaluate(values[1]),
              case .value(let r) = evaluator.evaluate(radius) else {
            Issue.record("Expected evaluable center/radius")
            return
        }
        #expect(abs(cx - 1.0) < 1e-9)
        #expect(abs(cy - 2.0) < 1e-9)
        #expect(abs(r - 3.0) < 1e-9)
    }

    @Test func xyTermConicFormClassifiesAsRotatedEllipse() throws {
        let expr = Expr.equation(
            left: .add([
                .multiply([x, y]),
                .power(base: x, exponent: .integer(2)),
                .power(base: y, exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
        #expect(info.orientation == .rotated)
        #expect(info.rotationAngle != nil)
    }

    @Test func expandedCircleEqualsZeroClassifiesAsCircle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .multiply([.integer(-2), x]),
                .power(base: y, exponent: .integer(2)),
                .multiply([.integer(-4), y]),
                .integer(-4)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .circle(let center, let radius) = result.intent else {
            Issue.record("Expected circle, got \(result.intent)")
            return
        }
        guard case .tuple(let values) = center, values.count == 2 else {
            Issue.record("Expected center tuple, got \(center)")
            return
        }
        let evaluator = ExprEvaluator()
        guard case .value(let cx) = evaluator.evaluate(values[0]),
              case .value(let cy) = evaluator.evaluate(values[1]),
              case .value(let r) = evaluator.evaluate(radius) else {
            Issue.record("Expected evaluable center/radius")
            return
        }
        #expect(abs(cx - 1.0) < 1e-9)
        #expect(abs(cy - 2.0) < 1e-9)
        #expect(abs(r - 3.0) < 1e-9)
    }

    @Test func expandedEllipseClassifiesAsConicEllipse() throws {
        let expr = Expr.equation(
            left: .add([
                .multiply([.integer(4), .power(base: x, exponent: .integer(2))]),
                .multiply([.integer(9), .power(base: y, exponent: .integer(2))]),
                .integer(-36)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
    }

    @Test func expandedHyperbolaXClassifiesAsConicHyperbolaX() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .negate(.power(base: y, exponent: .integer(2))),
                .integer(-1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .hyperbola)
        #expect(info.canonicalForm == .translatedHyperbolaX(
            center: .tuple([.real(0), .real(0)]),
            a: .function(.sqrt, arguments: [.real(1)]),
            b: .function(.sqrt, arguments: [.real(1)])
        ))
    }

    @Test func expandedHyperbolaYClassifiesAsConicHyperbolaY() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: y, exponent: .integer(2)),
                .negate(.power(base: x, exponent: .integer(2))),
                .integer(-1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .hyperbola)
        #expect(info.canonicalForm == .translatedHyperbolaY(
            center: .tuple([.real(0), .real(0)]),
            a: .function(.sqrt, arguments: [.real(1)]),
            b: .function(.sqrt, arguments: [.real(1)])
        ))
    }

    @Test func rotatedEllipseClassifiesAsConicWithRotationAngle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .multiply([.integer(2), x, y]),
                .multiply([.integer(3), .power(base: y, exponent: .integer(2))]),
                .integer(-1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
        #expect(info.orientation == .rotated)
        #expect(info.rotationAngle != nil)
    }

    @Test func rotatedHyperbolaClassifiesAsConicWithRotationAngle() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .multiply([.integer(4), x, y]),
                .power(base: y, exponent: .integer(2)),
                .integer(-1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .hyperbola)
        #expect(info.orientation == .rotated)
        #expect(info.rotationAngle != nil)
    }

    @Test func xyDegenerateFormFallsBackToImplicit() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .multiply([.integer(2), x, y]),
                .power(base: y, exponent: .integer(2)),
                .integer(-1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        if case .implicit = result.intent {
            #expect(Bool(true))
        } else {
            Issue.record("Expected implicit fallback, got \(result.intent)")
        }
    }

    @Test func nonRotatedQuadraticNoRealSolutionFallsBackToImplicit() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .power(base: y, exponent: .integer(2)),
                .integer(1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        if case .implicit = result.intent {
            #expect(Bool(true))
        } else {
            Issue.record("Expected implicit fallback, got \(result.intent)")
        }
    }

    @Test func symbolicCoefficientFallsBackToImplicit() throws {
        let a = Expr.symbol(Symbol(name: "a", role: .parameter))
        let expr = Expr.equation(
            left: .add([
                .multiply([a, .power(base: x, exponent: .integer(2))]),
                .power(base: y, exponent: .integer(2)),
                .integer(-1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        if case .implicit = result.intent {
            #expect(Bool(true))
        } else {
            Issue.record("Expected implicit fallback, got \(result.intent)")
        }
    }

    @Test func translatedEllipseClassifiesAsConicEllipse() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(
                    numerator: .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                    denominator: .integer(4)
                ),
                .divide(
                    numerator: .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                    denominator: .integer(9)
                )
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
        #expect(info.canonicalForm == .translatedEllipse(
            center: .tuple([.integer(1), .integer(2)]),
            a: .function(.sqrt, arguments: [.integer(4)]),
            b: .function(.sqrt, arguments: [.integer(9)])
        ))
    }

    @Test func translatedEllipseWithPlusShiftClassifiesAsConicEllipse() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(
                    numerator: .power(base: .add([x, .integer(1)]), exponent: .integer(2)),
                    denominator: .integer(4)
                ),
                .divide(
                    numerator: .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                    denominator: .integer(9)
                )
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
        guard case .translatedEllipse(let center, let aAxis, let bAxis) = info.canonicalForm else {
            Issue.record("Expected translatedEllipse canonical form, got \(String(describing: info.canonicalForm))")
            return
        }
        guard case .tuple(let centerValues) = center, centerValues.count == 2 else {
            Issue.record("Expected tuple center, got \(center)")
            return
        }
        let evaluator = ExprEvaluator()
        guard case .value(let cx) = evaluator.evaluate(centerValues[0]),
              case .value(let cy) = evaluator.evaluate(centerValues[1]),
              case .value(let aValue) = evaluator.evaluate(aAxis),
              case .value(let bValue) = evaluator.evaluate(bAxis) else {
            Issue.record("Expected evaluable center and axes")
            return
        }
        #expect(abs(cx - (-1.0)) < 1e-9)
        #expect(abs(cy - 2.0) < 1e-9)
        #expect(abs(aValue - 2.0) < 1e-9)
        #expect(abs(bValue - 3.0) < 1e-9)
    }

    @Test func translatedEllipseSwappedTermsAndSidesClassifiesAsConicEllipse() throws {
        let lhs = Expr.add([
            .divide(
                numerator: .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                denominator: .integer(9)
            ),
            .divide(
                numerator: .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                denominator: .integer(4)
            )
        ])
        let expr = Expr.equation(left: .integer(1), right: lhs)
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .ellipse)
    }

    @Test func translatedHyperbolaXClassifiesAsConicHyperbolaX() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(
                    numerator: .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                    denominator: .integer(4)
                ),
                .negate(
                    .divide(
                        numerator: .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                        denominator: .integer(9)
                    )
                )
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .hyperbola)
        #expect(info.canonicalForm == .translatedHyperbolaX(
            center: .tuple([.integer(1), .integer(2)]),
            a: .function(.sqrt, arguments: [.integer(4)]),
            b: .function(.sqrt, arguments: [.integer(9)])
        ))
    }

    @Test func translatedHyperbolaYClassifiesAsConicHyperbolaY() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(
                    numerator: .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                    denominator: .integer(9)
                ),
                .negate(
                    .divide(
                        numerator: .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                        denominator: .integer(4)
                    )
                )
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic, got \(result.intent)")
            return
        }
        #expect(info.kind == .hyperbola)
        #expect(info.canonicalForm == .translatedHyperbolaY(
            center: .tuple([.integer(1), .integer(2)]),
            a: .function(.sqrt, arguments: [.integer(4)]),
            b: .function(.sqrt, arguments: [.integer(9)])
        ))
    }

    @Test func translatedConicWithNonPositiveDenominatorFallsBackToImplicit() throws {
        let expr = Expr.equation(
            left: .add([
                .divide(
                    numerator: .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                    denominator: .integer(-4)
                ),
                .divide(
                    numerator: .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                    denominator: .integer(9)
                )
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .implicit(relation: expr))
    }

    @Test func translatedConicWithSymbolicDenominatorFallsBackToImplicit() throws {
        let a = Expr.symbol(Symbol(name: "a", role: .parameter))
        let expr = Expr.equation(
            left: .add([
                .divide(
                    numerator: .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                    denominator: a
                ),
                .divide(
                    numerator: .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                    denominator: .integer(9)
                )
            ]),
            right: .integer(1)
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .implicit(relation: expr))
    }

    @Test func nonRotatedParabolaYClassifiesAsConicParabola() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .negate(y)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic parabola, got \(result.intent)")
            return
        }
        #expect(info.kind == .parabola)
        guard case .translatedParabolaY(let vertex, let coefficient) = info.canonicalForm else {
            Issue.record("Expected translatedParabolaY, got \(String(describing: info.canonicalForm))")
            return
        }
        guard case .tuple(let values) = vertex, values.count == 2 else {
            Issue.record("Expected vertex tuple")
            return
        }
        let evaluator = ExprEvaluator()
        guard case .value(let h) = evaluator.evaluate(values[0]),
              case .value(let k) = evaluator.evaluate(values[1]),
              case .value(let c) = evaluator.evaluate(coefficient) else {
            Issue.record("Expected evaluable parabola parameters")
            return
        }
        #expect(abs(h - 0.0) < 1e-9)
        #expect(abs(k - 0.0) < 1e-9)
        #expect(abs(c - 1.0) < 1e-9)
    }

    @Test func nonRotatedParabolaYShiftedClassifiesAsConicParabola() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .multiply([.integer(-2), x]),
                .negate(y),
                .integer(1)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic parabola, got \(result.intent)")
            return
        }
        #expect(info.kind == .parabola)
        guard case .translatedParabolaY(let vertex, let coefficient) = info.canonicalForm else {
            Issue.record("Expected translatedParabolaY, got \(String(describing: info.canonicalForm))")
            return
        }
        guard case .tuple(let values) = vertex, values.count == 2 else {
            Issue.record("Expected vertex tuple")
            return
        }
        let evaluator = ExprEvaluator()
        guard case .value(let h) = evaluator.evaluate(values[0]),
              case .value(let k) = evaluator.evaluate(values[1]),
              case .value(let c) = evaluator.evaluate(coefficient) else {
            Issue.record("Expected evaluable parabola parameters")
            return
        }
        #expect(abs(h - 1.0) < 1e-9)
        #expect(abs(k - 0.0) < 1e-9)
        #expect(abs(c - 1.0) < 1e-9)
    }

    @Test func nonRotatedParabolaXClassifiesAsConicParabola() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: y, exponent: .integer(2)),
                .negate(x)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic parabola, got \(result.intent)")
            return
        }
        #expect(info.kind == .parabola)
        guard case .translatedParabolaX(let vertex, let coefficient) = info.canonicalForm else {
            Issue.record("Expected translatedParabolaX, got \(String(describing: info.canonicalForm))")
            return
        }
        guard case .tuple(let values) = vertex, values.count == 2 else {
            Issue.record("Expected vertex tuple")
            return
        }
        let evaluator = ExprEvaluator()
        guard case .value(let h) = evaluator.evaluate(values[0]),
              case .value(let k) = evaluator.evaluate(values[1]),
              case .value(let c) = evaluator.evaluate(coefficient) else {
            Issue.record("Expected evaluable parabola parameters")
            return
        }
        #expect(abs(h - 0.0) < 1e-9)
        #expect(abs(k - 0.0) < 1e-9)
        #expect(abs(c - 1.0) < 1e-9)
    }

    @Test func nonRotatedParabolaXShiftedClassifiesAsConicParabola() throws {
        let expr = Expr.equation(
            left: .add([
                .power(base: y, exponent: .integer(2)),
                .multiply([.integer(-4), y]),
                .negate(x)
            ]),
            right: .integer(0)
        )
        let result = classifier.classify(expr)
        guard case .conic(let info) = result.intent else {
            Issue.record("Expected conic parabola, got \(result.intent)")
            return
        }
        #expect(info.kind == .parabola)
        guard case .translatedParabolaX(let vertex, let coefficient) = info.canonicalForm else {
            Issue.record("Expected translatedParabolaX, got \(String(describing: info.canonicalForm))")
            return
        }
        guard case .tuple(let values) = vertex, values.count == 2 else {
            Issue.record("Expected vertex tuple")
            return
        }
        let evaluator = ExprEvaluator()
        guard case .value(let h) = evaluator.evaluate(values[0]),
              case .value(let k) = evaluator.evaluate(values[1]),
              case .value(let c) = evaluator.evaluate(coefficient) else {
            Issue.record("Expected evaluable parabola parameters")
            return
        }
        #expect(abs(h - (-4.0)) < 1e-9)
        #expect(abs(k - 2.0) < 1e-9)
        #expect(abs(c - 1.0) < 1e-9)
    }

    @Test func conicInfoLegacyInitStillWorks() throws {
        let source = Expr.unknown("legacy")
        let info = ConicInfo(kind: .ellipse, source: source)
        #expect(info.kind == .ellipse)
        #expect(info.source == source)
        #expect(info.canonicalForm == nil)
        #expect(info.orientation == nil)
        #expect(info.rotationAngle == nil)
    }

    @Test func conicInfoStoresRotationAngle() throws {
        let info = ConicInfo(
            kind: .ellipse,
            source: .unknown("rotated"),
            canonicalForm: .originEllipse(a: .integer(2), b: .integer(3)),
            orientation: .rotated,
            rotationAngle: Double.pi / 4
        )
        #expect(info.orientation == .rotated)
        #expect(abs((info.rotationAngle ?? 0) - Double.pi / 4) < 1e-12)
    }

    @Test func conicInfoSupportsOriginEllipseCanonicalForm() throws {
        let info = ConicInfo(
            kind: .ellipse,
            source: .unknown("ellipse"),
            canonicalForm: .originEllipse(a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        #expect(info.kind == .ellipse)
        #expect(info.orientation == .axisAligned)
        #expect(info.canonicalForm == .originEllipse(a: .integer(2), b: .integer(3)))
    }

    @Test func conicInfoSupportsOriginHyperbolaXCanonicalForm() throws {
        let info = ConicInfo(
            kind: .hyperbola,
            source: .unknown("hyperbolaX"),
            canonicalForm: .originHyperbolaX(a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        #expect(info.canonicalForm == .originHyperbolaX(a: .integer(2), b: .integer(3)))
    }

    @Test func conicInfoSupportsOriginHyperbolaYCanonicalForm() throws {
        let info = ConicInfo(
            kind: .hyperbola,
            source: .unknown("hyperbolaY"),
            canonicalForm: .originHyperbolaY(a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        #expect(info.canonicalForm == .originHyperbolaY(a: .integer(2), b: .integer(3)))
    }

    @Test func conicInfoSupportsTranslatedForms() throws {
        let center = Expr.tuple([.integer(1), .integer(2)])
        let ellipse = ConicInfo(
            kind: .ellipse,
            source: .unknown("translatedEllipse"),
            canonicalForm: .translatedEllipse(center: center, a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        #expect(ellipse.canonicalForm == .translatedEllipse(center: center, a: .integer(2), b: .integer(3)))

        let hyperbolaX = ConicInfo(
            kind: .hyperbola,
            source: .unknown("translatedHyperbolaX"),
            canonicalForm: .translatedHyperbolaX(center: center, a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        #expect(hyperbolaX.canonicalForm == .translatedHyperbolaX(center: center, a: .integer(2), b: .integer(3)))

        let hyperbolaY = ConicInfo(
            kind: .hyperbola,
            source: .unknown("translatedHyperbolaY"),
            canonicalForm: .translatedHyperbolaY(center: center, a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        #expect(hyperbolaY.canonicalForm == .translatedHyperbolaY(center: center, a: .integer(2), b: .integer(3)))

        let parabolaY = ConicInfo(
            kind: .parabola,
            source: .unknown("translatedParabolaY"),
            canonicalForm: .translatedParabolaY(vertex: center, coefficient: .real(1)),
            orientation: .axisAligned
        )
        #expect(parabolaY.canonicalForm == .translatedParabolaY(vertex: center, coefficient: .real(1)))

        let parabolaX = ConicInfo(
            kind: .parabola,
            source: .unknown("translatedParabolaX"),
            canonicalForm: .translatedParabolaX(vertex: center, coefficient: .real(2)),
            orientation: .axisAligned
        )
        #expect(parabolaX.canonicalForm == .translatedParabolaX(vertex: center, coefficient: .real(2)))
    }

    @Test func conicInfoCodableRoundTripPreservesCanonicalForm() throws {
        let original = ConicInfo(
            kind: .ellipse,
            source: .unknown("roundtrip"),
            canonicalForm: .originEllipse(a: .integer(2), b: .integer(3)),
            orientation: .axisAligned
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ConicInfo.self, from: encoded)
        #expect(decoded == original)
    }

    @Test func conicInfoCodableRoundTripPreservesRotationAngle() throws {
        let original = ConicInfo(
            kind: .hyperbola,
            source: .unknown("roundtripRot"),
            canonicalForm: .translatedHyperbolaX(
                center: .tuple([.real(1), .real(2)]),
                a: .real(3),
                b: .real(4)
            ),
            orientation: .rotated,
            rotationAngle: Double.pi / 6
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ConicInfo.self, from: encoded)
        #expect(decoded == original)
    }

    @Test func graphIntentConicEquatableStillWorks() throws {
        let left = GraphIntent.conic(
            ConicInfo(
                kind: .ellipse,
                source: .unknown("same"),
                canonicalForm: .originEllipse(a: .integer(2), b: .integer(3)),
                orientation: .axisAligned
            )
        )
        let right = GraphIntent.conic(
            ConicInfo(
                kind: .ellipse,
                source: .unknown("same"),
                canonicalForm: .originEllipse(a: .integer(2), b: .integer(3)),
                orientation: .axisAligned
            )
        )
        #expect(left == right)
    }

    @Test func tupleOfXYEquationsClassifiesAsParametric2D() throws {
        let expr = Expr.tuple([
            .equation(
                left: .symbol(Symbol(name: "x", role: .variable)),
                right: .add([
                    .power(base: t, exponent: .integer(2)),
                    .integer(1)
                ])
            ),
            .equation(
                left: .symbol(Symbol(name: "y", role: .variable)),
                right: t
            )
        ])
        let result = classifier.classify(expr)
        guard case .parametric2D(let xExpr, let yExpr, let parameter, let range) = result.intent else {
            Issue.record("Expected parametric2D intent, got \(result.intent)")
            return
        }
        #expect(parameter == Symbol(name: "t", role: .parameter))
        #expect(yExpr == t)
        #expect(range == nil)
        if case .add(let terms) = xExpr {
            #expect(terms.count == 2)
            #expect(terms.contains(.power(base: t, exponent: .integer(2))))
            #expect(terms.contains(.integer(1)))
        } else {
            Issue.record("Expected x expression to be add, got \(xExpr)")
        }
    }

    @Test func tupleOfYXEquationsClassifiesAsParametric2D() throws {
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: t),
            .equation(
                left: .symbol(Symbol(name: "x", role: .variable)),
                right: .add([
                    .power(base: t, exponent: .integer(2)),
                    .integer(1)
                ])
            )
        ])
        let result = classifier.classify(expr)
        guard case .parametric2D(let xExpr, let yExpr, let parameter, let range) = result.intent else {
            Issue.record("Expected parametric2D intent, got \(result.intent)")
            return
        }
        #expect(parameter == Symbol(name: "t", role: .parameter))
        #expect(yExpr == t)
        #expect(range == nil)
        if case .add(let terms) = xExpr {
            #expect(terms.count == 2)
            #expect(terms.contains(.power(base: t, exponent: .integer(2))))
            #expect(terms.contains(.integer(1)))
        } else {
            Issue.record("Expected x expression to be add, got \(xExpr)")
        }
    }

    @Test func tupleOfXYRelationsEqualClassifiesAsParametric2D() throws {
        let expr = Expr.tuple([
            .relation(
                left: .symbol(Symbol(name: "x", role: .variable)),
                relation: .equal,
                right: .function(.cos, arguments: [t])
            ),
            .relation(
                left: .symbol(Symbol(name: "y", role: .variable)),
                relation: .equal,
                right: .function(.sin, arguments: [t])
            )
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: .function(.cos, arguments: [t]),
            y: .function(.sin, arguments: [t]),
            parameter: Symbol(name: "t", role: .parameter),
            range: nil
        ))
    }

    @Test func tupleOfXYEquationsWithAmbiguousParametersReturnsUnknown() throws {
        let s = Expr.symbol(Symbol(name: "s", role: .parameter))
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: .add([t, s])),
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: t)
        ])
        let result = classifier.classify(expr)
        if case .unknown = result.intent {
            #expect(result.diagnostics.contains { $0.code == .ambiguousVariables })
        } else {
            #expect(Bool(false))
        }
    }

    @Test func tupleOfXYEquationsWithChainedRangeClassifiesParametricWithRange() throws {
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: .power(base: t, exponent: .integer(2))),
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: .multiply([.integer(2), t])),
            .chainedRelation(
                expressions: [.integer(0), t, .integer(3)],
                relations: [.lessOrEqual, .lessOrEqual]
            )
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: .power(base: t, exponent: .integer(2)),
            y: .multiply([.integer(2), t]),
            parameter: Symbol(name: "t", role: .parameter),
            range: ParameterRange(lower: .integer(0), upper: .integer(3))
        ))
    }

    @Test func tupleOfXYEquationsWithOpenChainedRangeClassifiesParametricWithRange() throws {
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: t),
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: .power(base: t, exponent: .integer(2))),
            .chainedRelation(
                expressions: [.integer(0), t, .integer(3)],
                relations: [.less, .less]
            )
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: t,
            y: .power(base: t, exponent: .integer(2)),
            parameter: Symbol(name: "t", role: .parameter),
            range: ParameterRange(lower: .integer(0), upper: .integer(3))
        ))
    }

    @Test func tupleOfXYEquationsWithSplitBoundsClassifiesParametricWithRange() throws {
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: t),
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: .power(base: t, exponent: .integer(2))),
            .relation(left: t, relation: .greaterOrEqual, right: .integer(0)),
            .relation(left: t, relation: .lessOrEqual, right: .integer(3))
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: t,
            y: .power(base: t, exponent: .integer(2)),
            parameter: Symbol(name: "t", role: .parameter),
            range: ParameterRange(lower: .integer(0), upper: .integer(3))
        ))
    }

    @Test func tupleOfXYEquationsWithSplitBoundsOtherDirectionClassifiesParametricWithRange() throws {
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: t),
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: .power(base: t, exponent: .integer(2))),
            .relation(left: .integer(0), relation: .lessOrEqual, right: t),
            .relation(left: t, relation: .lessOrEqual, right: .integer(3))
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: t,
            y: .power(base: t, exponent: .integer(2)),
            parameter: Symbol(name: "t", role: .parameter),
            range: ParameterRange(lower: .integer(0), upper: .integer(3))
        ))
    }

    @Test func tupleOfXYEquationsWithReverseChainedRangeClassifiesParametricWithRange() throws {
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: t),
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: .power(base: t, exponent: .integer(2))),
            .chainedRelation(expressions: [.integer(1), t, .integer(0)], relations: [.greater, .greater])
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: t,
            y: .power(base: t, exponent: .integer(2)),
            parameter: Symbol(name: "t", role: .parameter),
            range: ParameterRange(lower: .integer(0), upper: .integer(1))
        ))
    }

    @Test func tupleOfXYEquationsWithStrictSplitBoundsClassifiesParametricWithRange() throws {
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: t),
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: .power(base: t, exponent: .integer(2))),
            .relation(left: t, relation: .greater, right: .integer(0)),
            .relation(left: t, relation: .less, right: .integer(1))
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: t,
            y: .power(base: t, exponent: .integer(2)),
            parameter: Symbol(name: "t", role: .parameter),
            range: ParameterRange(lower: .integer(0), upper: .integer(1))
        ))
    }

    @Test func tupleOfXYEquationsWithoutRangeStillParametricWithNilRange() throws {
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: t),
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: .power(base: t, exponent: .integer(2)))
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: t,
            y: .power(base: t, exponent: .integer(2)),
            parameter: Symbol(name: "t", role: .parameter),
            range: nil
        ))
    }

    @Test func tupleOfXYEquationsWithMismatchedRangeVariableReturnsUnknown() throws {
        let s = Expr.symbol(Symbol(name: "s", role: .parameter))
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: t),
            .equation(left: .symbol(Symbol(name: "y", role: .variable)), right: .power(base: t, exponent: .integer(2))),
            .chainedRelation(expressions: [.integer(0), s, .integer(3)], relations: [.lessOrEqual, .lessOrEqual])
        ])
        let result = classifier.classify(expr)
        guard case .unknown = result.intent else {
            Issue.record("Expected unknown fallback, got \(result.intent)")
            return
        }
        #expect(result.diagnostics.contains { $0.code == .ambiguousVariables })
    }

    @Test func tupleOfSinCosWithTwoPiRangeClassifiesParametricWithMultiplyPiUpperBound() throws {
        let expr = Expr.tuple([
            .equation(
                left: .symbol(Symbol(name: "x", role: .variable)),
                right: .function(.sin, arguments: [t])
            ),
            .equation(
                left: .symbol(Symbol(name: "y", role: .variable)),
                right: .function(.cos, arguments: [t])
            ),
            .chainedRelation(
                expressions: [.integer(0), t, .multiply([.integer(2), .constant(.pi)])],
                relations: [.less, .less]
            )
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: .function(.sin, arguments: [t]),
            y: .function(.cos, arguments: [t]),
            parameter: Symbol(name: "t", role: .parameter),
            range: ParameterRange(lower: .integer(0), upper: .multiply([.integer(2), .constant(.pi)]))
        ))
    }

    @Test func rEqualsSinThetaClassifiesAsPolar() throws {
        let theta = Expr.symbol(Symbol(name: "θ", role: .unknown))
        let expr = Expr.equation(
            left: .symbol(Symbol(name: "r", role: .unknown)),
            right: .function(.sin, arguments: [theta])
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .polar(
            radius: .function(.sin, arguments: [theta]),
            angle: Symbol(name: "θ", role: .parameter),
            range: nil
        ))
    }

    @Test func rEqualsSinTClassifiesAsPolarWithTAngle() throws {
        let expr = Expr.equation(
            left: .symbol(Symbol(name: "r", role: .unknown)),
            right: .function(.sin, arguments: [t])
        )
        let result = classifier.classify(expr)
        #expect(result.intent == .polar(
            radius: .function(.sin, arguments: [t]),
            angle: Symbol(name: "t", role: .parameter),
            range: nil
        ))
    }

    @Test func polarTupleWithRangeClassifiesAsPolarWithRange() throws {
        let theta = Expr.symbol(Symbol(name: "θ", role: .unknown))
        let expr = Expr.tuple([
            .relation(
                left: .symbol(Symbol(name: "r", role: .unknown)),
                relation: .equal,
                right: .function(.sin, arguments: [.multiply([.integer(3), theta])])
            ),
            .chainedRelation(
                expressions: [.integer(0), theta, .multiply([.integer(2), .constant(.pi)])],
                relations: [.lessOrEqual, .lessOrEqual]
            )
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .polar(
            radius: .function(.sin, arguments: [.multiply([.integer(3), theta])]),
            angle: Symbol(name: "θ", role: .parameter),
            range: ParameterRange(lower: .integer(0), upper: .multiply([.integer(2), .constant(.pi)]))
        ))
    }

    @Test func polarWithMultipleVariablesReturnsAmbiguousVariables() throws {
        let theta = Expr.symbol(Symbol(name: "θ", role: .unknown))
        let a = Expr.symbol(Symbol(name: "a", role: .unknown))
        let expr = Expr.equation(
            left: .symbol(Symbol(name: "r", role: .unknown)),
            right: .function(.sin, arguments: [.multiply([a, theta])])
        )
        let result = classifier.classify(expr)
        if case .unknown = result.intent {
            #expect(result.diagnostics.contains { $0.code == .ambiguousVariables })
        } else {
            #expect(Bool(false))
        }
    }

    @Test func circleCustomFunctionClassifiesAsCircle() throws {
        let expr = Expr.function(.custom("circle"), arguments: [
            .tuple([.integer(0), .integer(0)]),
            .integer(1)
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .circle(
            center: .tuple([.integer(0), .integer(0)]),
            radius: .integer(1)
        ))
    }

    @Test func circleCustomFunctionPreservesCenterAndRadius() throws {
        let expr = Expr.function(.custom("circle"), arguments: [
            .tuple([.integer(1), .integer(2)]),
            .integer(3)
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .circle(
            center: .tuple([.integer(1), .integer(2)]),
            radius: .integer(3)
        ))
    }

    @Test func circleCustomFunctionWithSqrtRadiusClassifiesAsCircle() throws {
        let expr = Expr.function(.custom("circle"), arguments: [
            .tuple([.integer(0), .integer(0)]),
            .function(.sqrt, arguments: [.integer(2)])
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .circle(
            center: .tuple([.integer(0), .integer(0)]),
            radius: .function(.sqrt, arguments: [.integer(2)])
        ))
    }

    @Test func circleCustomFunctionWrongArityDoesNotClassifyAsCircle() throws {
        let expr = Expr.function(.custom("circle"), arguments: [
            .tuple([.integer(0), .integer(0)])
        ])
        let result = classifier.classify(expr)
        if case .unknown = result.intent {
            #expect(result.diagnostics.contains { $0.code == .unsupportedExpression })
        } else {
            #expect(Bool(false))
        }
    }

    @Test func circleCustomFunctionCenterNotTupleDoesNotClassifyAsCircle() throws {
        let expr = Expr.function(.custom("circle"), arguments: [
            .integer(0),
            .integer(1)
        ])
        let result = classifier.classify(expr)
        if case .unknown = result.intent {
            #expect(result.diagnostics.contains { $0.code == .unsupportedExpression })
        } else {
            #expect(Bool(false))
        }
    }

    @Test func parametricTupleUsesRangeVariableWhenExpressionsAreConstant() throws {
        let s = Symbol(name: "s", role: .parameter)
        let expr = Expr.tuple([
            .equation(left: x, right: .integer(1)),
            .equation(left: y, right: .integer(2)),
            .chainedRelation(
                expressions: [.integer(0), .symbol(s), .integer(1)],
                relations: [.less, .less]
            )
        ])

        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: .integer(1),
            y: .integer(2),
            parameter: s,
            range: ParameterRange(lower: .integer(0), upper: .integer(1))
        ))
    }

    @Test func parametricTupleRangeVariableMismatchFallsBackUnknown() throws {
        let s = Symbol(name: "s", role: .parameter)
        let t = Symbol(name: "t", role: .parameter)
        let expr = Expr.tuple([
            .equation(left: x, right: .symbol(s)),
            .equation(left: y, right: .power(base: .symbol(s), exponent: .integer(2))),
            .chainedRelation(
                expressions: [.integer(0), .symbol(t), .integer(1)],
                relations: [.less, .less]
            )
        ])

        let result = classifier.classify(expr)
        guard case .unknown = result.intent else {
            Issue.record("Expected unknown fallback, got \(result.intent)")
            return
        }
        #expect(result.diagnostics.contains { $0.code == .ambiguousVariables })
    }

    @Test func tupleOfXYEquationsWithSRangeClassifiesParametricWithS() throws {
        let s = Expr.symbol(Symbol(name: "s", role: .parameter))
        let expr = Expr.tuple([
            .equation(left: .symbol(Symbol(name: "x", role: .variable)), right: s),
            .equation(
                left: .symbol(Symbol(name: "y", role: .variable)),
                right: .power(base: s, exponent: .integer(2))
            ),
            .chainedRelation(
                expressions: [.integer(-1), s, .integer(2)],
                relations: [.less, .less]
            )
        ])
        let result = classifier.classify(expr)
        #expect(result.intent == .parametric2D(
            x: s,
            y: .power(base: s, exponent: .integer(2)),
            parameter: Symbol(name: "s", role: .parameter),
            range: ParameterRange(lower: .integer(-1), upper: .integer(2))
        ))
    }

    @Test func tupleOfSinCosWithURangeClassifiesParametricWithU() throws {
        let u = Expr.symbol(Symbol(name: "u", role: .parameter))
        let expr = Expr.tuple([
            .equation(
                left: .symbol(Symbol(name: "x", role: .variable)),
                right: .function(.sin, arguments: [u])
            ),
            .equation(
                left: .symbol(Symbol(name: "y", role: .variable)),
                right: .function(.cos, arguments: [u])
            ),
            .chainedRelation(
                expressions: [.integer(0), u, .multiply([.integer(2), .constant(.pi)])],
                relations: [.lessOrEqual, .lessOrEqual]
            )
        ])
        let result = classifier.classify(expr)
        guard case .parametric2D(_, _, let parameter, let range) = result.intent else {
            Issue.record("Expected parametric2D intent, got \(result.intent)")
            return
        }
        #expect(parameter == Symbol(name: "u", role: .parameter))
        guard let upper = range?.upper else {
            Issue.record("Expected range upper")
            return
        }
        let evaluated = ExprEvaluator().evaluate(upper)
        guard case .value(let value) = evaluated else {
            Issue.record("Expected evaluable upper bound")
            return
        }
        #expect(abs(value - 2 * Double.pi) < 1e-9)
    }
}
