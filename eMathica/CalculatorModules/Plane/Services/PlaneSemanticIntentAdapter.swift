import EMathicaWorkspaceKit
import Foundation
import EMathicaMathCore

/// Plane-module implementation of `SemanticIntentAdapterProtocol`.
/// Wraps the existing `PlaneSemanticGraphIntentAdapter` static methods.
struct PlaneSemanticIntentAdapter: SemanticIntentAdapterProtocol {

    func semanticGraphKind(from intent: GraphIntent?) -> SemanticGraphKind? {
        PlaneSemanticGraphIntentAdapter.semanticGraphKind(from: intent)
    }

    func parameterSymbol(from intent: GraphIntent?) -> Symbol? {
        PlaneSemanticGraphIntentAdapter.parameterSymbol(from: intent)
    }

    func parameterRange(from intent: GraphIntent?) -> ParameterRange? {
        PlaneSemanticGraphIntentAdapter.parameterRange(from: intent)
    }

    func metadataText(
        semanticGraphKind: SemanticGraphKind?,
        semanticParameterSymbol: Symbol?,
        semanticParameterRange: ParameterRange?,
        algebraAnalysis: AlgebraAnalysisResult?
    ) -> String? {
        PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: semanticGraphKind,
            semanticParameterSymbol: semanticParameterSymbol,
            semanticParameterRange: semanticParameterRange,
            algebraAnalysis: algebraAnalysis
        )
    }
}
