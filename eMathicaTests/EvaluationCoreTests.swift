import Testing
import Foundation
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct EvaluationCoreTests {
    private let evaluator = ExprEvaluator()

    @Test func evaluatesInteger() throws {
        #expect(evaluator.evaluate(.integer(2)) == .value(2))
    }

    @Test func evaluatesRational() throws {
        #expect(evaluator.evaluate(.rational(numerator: 1, denominator: 2)) == .value(0.5))
    }

    @Test func evaluatesDecimal() throws {
        #expect(evaluator.evaluate(.decimal("0.100")) == .value(0.1))
    }

    @Test func evaluatesPiConstant() throws {
        if case .value(let value) = evaluator.evaluate(.constant(.pi)) {
            #expect(abs(value - Double.pi) < 1e-12)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func evaluatesSymbolFromEnvironment() throws {
        let env = EvaluationEnvironment.variables(["x": 3])
        #expect(evaluator.evaluate(.symbol(Symbol(name: "x", role: .variable)), environment: env) == .value(3))
    }

    @Test func missingSymbolProducesIssue() throws {
        if case .undefined(let issue) = evaluator.evaluate(.symbol(Symbol(name: "x", role: .variable))) {
            #expect(issue.kind == .missingVariable)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func addMultiplyNegateDividePower() throws {
        #expect(evaluator.evaluate(.add([.integer(2), .integer(3)])) == .value(5))
        #expect(evaluator.evaluate(.multiply([.integer(2), .integer(3)])) == .value(6))
        #expect(evaluator.evaluate(.negate(.integer(2))) == .value(-2))
        #expect(evaluator.evaluate(.divide(numerator: .integer(1), denominator: .integer(2))) == .value(0.5))
        #expect(evaluator.evaluate(.power(base: .integer(2), exponent: .integer(3))) == .value(8))
    }

    @Test func divideByZeroIssue() throws {
        if case .undefined(let issue) = evaluator.evaluate(.divide(numerator: .integer(1), denominator: .integer(0))) {
            #expect(issue.kind == .divisionByZero)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func trigonometricFunctions() throws {
        let halfPi = Expr.divide(numerator: .constant(.pi), denominator: .integer(2))
        if case .value(let value) = evaluator.evaluate(.function(.sin, arguments: [halfPi])) {
            #expect(abs(value - 1) < 1e-9)
        } else {
            #expect(Bool(false))
        }
        #expect(evaluator.evaluate(.function(.cos, arguments: [.integer(0)])) == .value(1))
    }

    @Test func tanUndefinedIssue() throws {
        let halfPi = Expr.divide(numerator: .constant(.pi), denominator: .integer(2))
        if case .undefined(let issue) = evaluator.evaluate(.function(.tan, arguments: [halfPi])) {
            #expect(issue.kind == .tangentUndefined)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func logarithmFamily() throws {
        if case .value(let lnE) = evaluator.evaluate(.function(.ln, arguments: [.constant(.e)])) {
            #expect(abs(lnE - 1) < 1e-9)
        } else {
            #expect(Bool(false))
        }

        #expect(evaluator.evaluate(.function(.lg, arguments: [.integer(100)])) == .value(2))

        if case .undefined(let issue) = evaluator.evaluate(.function(.log, arguments: [.integer(100)])) {
            #expect(issue.kind == .ambiguousLogBase)
        } else {
            #expect(Bool(false))
        }

        #expect(evaluator.evaluate(.function(.logBase, arguments: [.integer(2), .integer(8)])) == .value(3))

        if case .undefined(let issue) = evaluator.evaluate(.function(.logBase, arguments: [.integer(1), .integer(8)])) {
            #expect(issue.kind == .invalidLogBase)
        } else {
            #expect(Bool(false))
        }

        if case .undefined(let issue) = evaluator.evaluate(.function(.logBase, arguments: [.integer(-2), .integer(8)])) {
            #expect(issue.kind == .invalidLogBase)
        } else {
            #expect(Bool(false))
        }

        if case .undefined(let issue) = evaluator.evaluate(.function(.logBase, arguments: [.integer(2), .integer(-8)])) {
            #expect(issue.kind == .logarithmOfNonPositive)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func sqrtAbsExp() throws {
        #expect(evaluator.evaluate(.function(.sqrt, arguments: [.integer(4)])) == .value(2))
        #expect(evaluator.evaluate(.function(.abs, arguments: [.integer(-3)])) == .value(3))

        if case .value(let value) = evaluator.evaluate(.function(.exp, arguments: [.integer(1)])) {
            #expect(abs(value - Foundation.exp(1)) < 1e-12)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func sqrtNegativeIssue() throws {
        if case .undefined(let issue) = evaluator.evaluate(.function(.sqrt, arguments: [.integer(-1)])) {
            #expect(issue.kind == .squareRootOfNegative)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func unsupportedEquation() throws {
        let expr = Expr.equation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            right: .integer(1)
        )
        if case .undefined(let issue) = evaluator.evaluate(expr) {
            #expect(issue.kind == .unsupportedExpression)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func nonFiniteOverflowIssue() throws {
        let expr = Expr.power(base: .real(1e308), exponent: .integer(2))
        if case .undefined(let issue) = evaluator.evaluate(expr) {
            #expect(issue.kind == .invalidPower)
        } else {
            #expect(Bool(false))
        }
    }
}
