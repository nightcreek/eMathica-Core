import EMathicaWorkspaceKit
import Foundation

/// Plane-module implementation of `InputCanonicalizerProtocol`.
///
/// Currently acts as an identity transform. The existing
/// `canonicalPlaneCommitInput` logic in `WorkspaceState` will be
/// migrated here during Phase 3 (WorkspaceState call site migration).
struct PlaneInputCanonicalizer: InputCanonicalizerProtocol {

    func canonicalize(
        source: String,
        semanticState: FormulaSemanticState
    ) -> String {
        // TODO: Migrate canonicalPlaneCommitInput logic from WorkspaceState
        // during Phase 3 call-site migration.
        source
    }
}
