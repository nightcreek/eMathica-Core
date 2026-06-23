import EMathicaWorkspaceKit
import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

/// Plane-module implementation of `GeometryDependencyServiceProtocol`.
/// Wraps the existing `PlaneGeometryDependencyRecomputeService` static methods.
struct PlaneGeometryDependencyService: GeometryDependencyServiceProtocol {

    func directlyAffectedDerivedObjectIDs(
        objects: [MathObject],
        candidateSourceIDs: Set<UUID>
    ) -> Set<UUID> {
        PlaneGeometryDependencyRecomputeService.directlyAffectedDerivedObjectIDs(
            objects: objects,
            candidateSourceIDs: candidateSourceIDs
        )
    }

    func downstreamAffectedDerivedObjectIDs(
        objects: [MathObject],
        candidateSourceIDs: Set<UUID>
    ) -> Set<UUID> {
        PlaneGeometryDependencyRecomputeService.downstreamAffectedDerivedObjectIDs(
            objects: objects,
            candidateSourceIDs: candidateSourceIDs
        )
    }

    func dependencyPatches(
        objects: [MathObject],
        changedSourceIDs: Set<UUID>
    ) -> [(UUID, DocumentObjectPatch)] {
        PlaneGeometryDependencyRecomputeService.dependencyPatches(
            objects: objects,
            changedSourceIDs: changedSourceIDs
        )
    }

    func dependencyCleanupPatchesForRemovedSources(
        objects: [MathObject],
        removedSourceIDs: Set<UUID>
    ) -> [(UUID, DocumentObjectPatch)] {
        PlaneGeometryDependencyRecomputeService.dependencyCleanupPatchesForRemovedSources(
            objects: objects,
            removedSourceIDs: removedSourceIDs
        )
    }
}
