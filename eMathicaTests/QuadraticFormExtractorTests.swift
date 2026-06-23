import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct QuadraticFormExtractorTests {
    private let x = Expr.symbol(Symbol(name: "x", role: .variable))
    private let y = Expr.symbol(Symbol(name: "y", role: .variable))

    @Test func extractUnitCircleExpanded() throws {
        let expr = Expr.add([
            .power(base: x, exponent: .integer(2)),
            .power(base: y, exponent: .integer(2)),
            .integer(-1)
        ])
        let form = try requireSuccess(QuadraticFormExtractor().extract(expr))
        #expect(form.xx == 1)
        #expect(form.yy == 1)
        #expect(form.constant == -1)
    }

    @Test func extractScaledQuadraticTerms() throws {
        let expr = Expr.add([
            .multiply([.integer(2), .power(base: x, exponent: .integer(2))]),
            .multiply([.integer(3), .power(base: y, exponent: .integer(2))]),
            .integer(-1)
        ])
        let form = try requireSuccess(QuadraticFormExtractor().extract(expr))
        #expect(form.xx == 2)
        #expect(form.yy == 3)
    }

    @Test func extractXYCoefficient() throws {
        let expr = Expr.add([
            .power(base: x, exponent: .integer(2)),
            .multiply([.integer(2), x, y]),
            .power(base: y, exponent: .integer(2)),
            .integer(-1)
        ])
        let form = try requireSuccess(QuadraticFormExtractor().extract(expr))
        #expect(form.xy == 2)
    }

    @Test func extractLinearTerms() throws {
        let expr = Expr.add([
            .power(base: x, exponent: .integer(2)),
            .multiply([.integer(-2), x]),
            .power(base: y, exponent: .integer(2)),
            .multiply([.integer(-4), y]),
            .integer(-4)
        ])
        let form = try requireSuccess(QuadraticFormExtractor().extract(expr))
        #expect(form.xx == 1)
        #expect(form.yy == 1)
        #expect(form.x == -2)
        #expect(form.y == -4)
        #expect(form.constant == -4)
    }

    @Test func extractNegativeQuadraticCoefficient() throws {
        let expr = Expr.add([
            .negate(.power(base: x, exponent: .integer(2))),
            .power(base: y, exponent: .integer(2)),
            .integer(1)
        ])
        let form = try requireSuccess(QuadraticFormExtractor().extract(expr))
        #expect(form.xx == -1)
        #expect(form.yy == 1)
        #expect(form.constant == 1)
    }

    @Test func extractDecimalAndRationalCoefficients() throws {
        let expr = Expr.add([
            .multiply([.decimal("0.5"), .power(base: x, exponent: .integer(2))]),
            .multiply([.rational(numerator: 1, denominator: 3), .power(base: y, exponent: .integer(2))]),
            .integer(-1)
        ])
        let form = try requireSuccess(QuadraticFormExtractor().extract(expr))
        #expect(abs(form.xx - 0.5) < 1e-12)
        #expect(abs(form.yy - (1.0 / 3.0)) < 1e-12)
    }

    @Test func rejectDegreeTooHigh() throws {
        let expr = Expr.add([
            .power(base: x, exponent: .integer(3)),
            .power(base: y, exponent: .integer(2))
        ])
        let diagnostics = try requireFailure(QuadraticFormExtractor().extract(expr))
        #expect(diagnostics.contains(where: { $0.code == .degreeTooHigh }))
    }

    @Test func rejectUnexpectedSymbol() throws {
        let z = Expr.symbol(Symbol(name: "z", role: .variable))
        let expr = Expr.add([
            .power(base: z, exponent: .integer(2)),
            .power(base: x, exponent: .integer(2))
        ])
        let diagnostics = try requireFailure(QuadraticFormExtractor().extract(expr))
        #expect(diagnostics.contains(where: { $0.code == .unexpectedSymbol }))
    }

    @Test func rejectFunctionTerm() throws {
        let expr = Expr.add([
            .function(.sin, arguments: [x]),
            .power(base: y, exponent: .integer(2))
        ])
        let diagnostics = try requireFailure(QuadraticFormExtractor().extract(expr))
        #expect(diagnostics.contains(where: { $0.code == .unsupportedQuadraticTerm }))
    }

    @Test func rejectSymbolicCoefficient() throws {
        let a = Expr.symbol(Symbol(name: "a", role: .parameter))
        let expr = Expr.add([
            .multiply([a, .power(base: x, exponent: .integer(2))]),
            .power(base: y, exponent: .integer(2))
        ])
        let diagnostics = try requireFailure(QuadraticFormExtractor().extract(expr))
        #expect(diagnostics.contains(where: { $0.code == .unsupportedCoefficient || $0.code == .unexpectedSymbol }))
    }

    @Test func rejectNonExpandedSquare() throws {
        let expr = Expr.add([
            .power(base: .add([x, .integer(1)]), exponent: .integer(2)),
            .power(base: y, exponent: .integer(2))
        ])
        let diagnostics = try requireFailure(QuadraticFormExtractor().extract(expr))
        #expect(diagnostics.contains(where: { $0.code == .unsupportedQuadraticTerm }))
    }
}

private func requireSuccess<T>(_ result: Result<T, ExprDiagnosticList>) throws -> T {
    switch result {
    case .success(let value):
        return value
    case .failure(let diagnostics):
        Issue.record("Expected success but got diagnostics: \(diagnostics.diagnostics)")
        throw TestFailure("unexpected failure")
    }
}

private func requireFailure<T>(_ result: Result<T, ExprDiagnosticList>) throws -> [ExprDiagnostic] {
    switch result {
    case .success:
        Issue.record("Expected failure but got success.")
        throw TestFailure("unexpected success")
    case .failure(let diagnostics):
        return diagnostics.diagnostics
    }
}

private struct TestFailure: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
