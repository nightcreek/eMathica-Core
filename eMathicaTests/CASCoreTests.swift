import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct CASCoreTests {
    private let x = Expr.symbol(Symbol(name: "x", role: .variable))
    private let y = Expr.symbol(Symbol(name: "y", role: .variable))

    @Test func normalizerAddFlatten() throws {
        let expr = Expr.add([.integer(1), .add([.integer(2), x])])
        let normalized = ExpressionNormalizer().normalize(expr)
        #expect(normalized == .add([.integer(1), .integer(2), x]))
    }

    @Test func normalizerMultiplyFlatten() throws {
        let expr = Expr.multiply([.integer(2), .multiply([x, y])])
        let normalized = ExpressionNormalizer().normalize(expr)
        #expect(normalized == .multiply([.integer(2), x, y]))
    }

    @Test func normalizerSingleElementAdd() throws {
        #expect(ExpressionNormalizer().normalize(.add([x])) == x)
    }

    @Test func normalizerSingleElementMultiply() throws {
        #expect(ExpressionNormalizer().normalize(.multiply([x])) == x)
    }

    @Test func simplifierAddZeroLeftRight() throws {
        let s = ExpressionSimplifier()
        #expect(s.simplify(.add([x, .integer(0)])) == x)
        #expect(s.simplify(.add([.integer(0), x])) == x)
    }

    @Test func simplifierAddIntegerFold() throws {
        #expect(ExpressionSimplifier().simplify(.add([.integer(2), .integer(3)])) == .integer(5))
    }

    @Test func simplifierMultiplyIdentityZeroAndFold() throws {
        let s = ExpressionSimplifier()
        #expect(s.simplify(.multiply([x, .integer(1)])) == x)
        #expect(s.simplify(.multiply([x, .integer(0)])) == .integer(0))
        #expect(s.simplify(.multiply([.integer(2), .integer(3)])) == .integer(6))
    }

    @Test func simplifierPowerRules() throws {
        let s = ExpressionSimplifier()
        #expect(s.simplify(.power(base: x, exponent: .integer(1))) == x)
        #expect(s.simplify(.power(base: x, exponent: .integer(0))) == .integer(1))
    }

    @Test func simplifierDoubleNegation() throws {
        #expect(ExpressionSimplifier().simplify(.negate(.negate(x))) == x)
    }

    @Test func simplifierDivideToRationalAndReduce() throws {
        let s = ExpressionSimplifier()
        #expect(s.simplify(.divide(numerator: .integer(1), denominator: .integer(3))) == .rational(numerator: 1, denominator: 3))
        #expect(s.simplify(.divide(numerator: .integer(2), denominator: .integer(4))) == .rational(numerator: 1, denominator: 2))
    }

    @Test func simplifierRationalSignNormalization() throws {
        #expect(ExpressionSimplifier().simplify(.rational(numerator: 1, denominator: -3)) == .rational(numerator: -1, denominator: 3))
    }

    @Test func canonicalizerSimplifiesAdd() throws {
        let canonical = Canonicalizer().canonicalize(.add([x, .integer(0)]))
        #expect(canonical == .symbol(Symbol(name: "x", role: .variable)))
    }

    @Test func canonicalizerSimplifiesMultiply() throws {
        let canonical = Canonicalizer().canonicalize(.multiply([.integer(2), x, .integer(1)]))
        #expect(canonical == .product([.integer(2), .symbol(Symbol(name: "x", role: .variable))]))
    }

    @Test func canonicalizerEquationToRelation() throws {
        let canonical = Canonicalizer().canonicalize(.equation(left: x, right: .integer(2)))
        #expect(canonical == .relation(CanonicalRelation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            relation: .equal,
            right: .integer(2)
        )))
    }
}
