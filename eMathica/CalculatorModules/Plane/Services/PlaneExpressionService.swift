import EMathicaWorkspaceKit
import EMathicaMathCore
import Foundation

enum PlaneExpressionService {
    static func buildExpression(from source: String, fallbackToExplicitY: Bool) -> Result<MathExpression, WorkspaceModuleBuildError> {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.message("请输入内容"))
        }
        let parseInput = fallbackToExplicitY && !trimmed.contains("=") ? "y=\(trimmed)" : trimmed
        let analysis = AlgebraCore.analyzePlaneLatex(parseInput)
        #if DEBUG
        print("[PlanePreview][ExpressionService] source=\"\(source)\" fallbackToExplicitY=\(fallbackToExplicitY) parseInput=\"\(parseInput)\" class=\(analysis.classification.kind) plot=\(analysis.plotStrategy) rewrite=\(analysis.rewriteInfo == nil ? "nil" : "\(analysis.rewriteInfo!.shapeKind)")")
        #endif
        if let error = analysis.diagnostics.first(where: { $0.severity == .error }) {
            return .failure(.message(error.message))
        }
        return .success(MathExpression.algebra(analysis))
    }
}
