import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct ConditionEvaluatorTests {
    private let evaluator = ConditionEvaluator()

    @Test func lessSatisfied() {
        let condition = Expr.relation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            relation: .less,
            right: .integer(1)
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 0]))
        #expect(result == .satisfied)
    }

    @Test func lessUnsatisfied() {
        let condition = Expr.relation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            relation: .less,
            right: .integer(1)
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 2]))
        #expect(result == .unsatisfied)
    }

    @Test func lessOrEqualSatisfiedAtBoundary() {
        let condition = Expr.relation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            relation: .lessOrEqual,
            right: .integer(1)
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 1]))
        #expect(result == .satisfied)
    }

    @Test func greaterSatisfied() {
        let condition = Expr.relation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            relation: .greater,
            right: .integer(0)
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 1]))
        #expect(result == .satisfied)
    }

    @Test func greaterOrEqualSatisfiedAtBoundary() {
        let condition = Expr.relation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            relation: .greaterOrEqual,
            right: .integer(0)
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 0]))
        #expect(result == .satisfied)
    }

    @Test func equationSatisfied() {
        let condition = Expr.equation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            right: .integer(1)
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 1]))
        #expect(result == .satisfied)
    }

    @Test func equationSatisfiedWithinEpsilon() {
        let eps = 1e-6
        let conditionEvaluator = ConditionEvaluator(options: .init(epsilon: eps))
        let condition = Expr.equation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            right: .integer(1)
        )
        let result = conditionEvaluator.evaluate(condition, environment: .variables(["x": 1 + eps / 2]))
        #expect(result == .satisfied)
    }

    @Test func notEqualSatisfied() {
        let condition = Expr.relation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            relation: .notEqual,
            right: .integer(1)
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 2]))
        #expect(result == .satisfied)
    }

    @Test func chainedRelationSatisfied() {
        let condition = Expr.chainedRelation(
            expressions: [.integer(0), .symbol(Symbol(name: "x", role: .variable)), .integer(1)],
            relations: [.less, .less]
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 0.5]))
        #expect(result == .satisfied)
    }

    @Test func chainedRelationUnsatisfied() {
        let condition = Expr.chainedRelation(
            expressions: [.integer(0), .symbol(Symbol(name: "x", role: .variable)), .integer(1)],
            relations: [.less, .less]
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 2]))
        #expect(result == .unsatisfied)
    }

    @Test func undefinedSidePropagates() {
        let condition = Expr.relation(
            left: .divide(
                numerator: .integer(1),
                denominator: .add([.symbol(Symbol(name: "x", role: .variable)), .integer(-1)])
            ),
            relation: .less,
            right: .integer(0)
        )
        let result = evaluator.evaluate(condition, environment: .variables(["x": 1]))
        if case .undefined(let issue) = result {
            #expect(issue.kind == .divisionByZero)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func unsupportedConditionReturnsUnsupportedExpression() {
        let condition = Expr.add([.integer(1), .integer(2)])
        let result = evaluator.evaluate(condition, environment: .init())
        if case .undefined(let issue) = result {
            #expect(issue.kind == .unsupportedExpression)
        } else {
            #expect(Bool(false))
        }
    }
}
