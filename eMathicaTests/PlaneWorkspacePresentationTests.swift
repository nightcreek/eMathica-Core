import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct PlaneWorkspacePresentationTests {
    @Test func planeLaunchStartsWithObjectPanelCollapsedAndCanBeReopened() {
        let state = makePlaneWorkspaceState(objects: [])

        #expect(state.isObjectPanelPresented == false)

        state.dispatch(.setObjectPanelVisible(true))
        #expect(state.isObjectPanelPresented == true)

        state.dispatch(.toggleObjectPanel)
        #expect(state.isObjectPanelPresented == false)
    }

    @Test func planeSelectionAutoRevealsInspectorAndClearingSelectionHidesItAgain() {
        let object = makePoint(name: "A", x: 1, y: 2)
        let state = makePlaneWorkspaceState(objects: [object])

        #expect(state.isInspectorPresented == false)

        state.dispatch(.clearSelection)
        #expect(state.isInspectorPresented == false)

        state.dispatch(.selectObject(id: object.id))
        #expect(state.isInspectorPresented == true)

        state.dispatch(.clearSelection)
        #expect(state.isInspectorPresented == false)
    }

    @Test func spaceKeepsLegacyPanelAndInspectorBehavior() {
        let object = makePoint(name: "P", x: 0, y: 0)
        let state = makeSpaceWorkspaceState(objects: [object])

        #expect(state.isObjectPanelPresented == true)
        #expect(state.isInspectorPresented == false)

        state.dispatch(.clearSelection)
        state.dispatch(.selectObject(id: object.id))

        #expect(state.isInspectorPresented == false)
    }

    private func makePlaneWorkspaceState(objects: [MathObject]) -> WorkspaceState {
        WorkspaceState(
            module: .plane,
            document: makeDocument(moduleID: "plane", title: "Plane Workspace Presentation Test", objects: objects),
            toolGroups: PlaneWorkspaceModuleProvider().toolGroups,
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    private func makeSpaceWorkspaceState(objects: [MathObject]) -> WorkspaceState {
        let provider = SpaceWorkspaceModuleProvider()
        return WorkspaceState(
            module: .space,
            document: makeDocument(moduleID: "space", title: "Space Workspace Presentation Test", objects: objects),
            toolGroups: provider.toolGroups,
            moduleProvider: provider
        )
    }

    private func makeDocument(moduleID: String, title: String, objects: [MathObject]) -> EMathicaDocument {
        let now = Date()
        let metadata = ProjectMetadata(
            title: title,
            moduleID: moduleID,
            createdAt: now,
            updatedAt: now,
            calculatorType: moduleID
        )
        return EMathicaDocument(metadata: metadata, moduleID: moduleID, objects: objects)
    }

    private func makePoint(name: String, x: Double, y: Double) -> MathObject {
        MathObject(
            name: name,
            type: .point,
            expression: MathExpression(displayText: "\(name) = (\(x), \(y))"),
            position: WorldPoint(x: x, y: y),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "blue")
        )
    }
}
