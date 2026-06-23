import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct ObjectPanelFullscreenTests {
    @Test func fullscreenFlagDefaultsToOffAndCanToggle() {
        let state = makeWorkspaceState(objects: [])

        #expect(state.isObjectPanelFullscreen == false)

        state.isObjectPanelFullscreen = true
        #expect(state.isObjectPanelFullscreen == true)

        state.isObjectPanelFullscreen = false
        #expect(state.isObjectPanelFullscreen == false)
    }

    private func makeWorkspaceState(objects: [MathObject]) -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "Object Panel Fullscreen Test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: objects)
        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneWorkspaceModuleProvider().toolGroups,
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }
}
