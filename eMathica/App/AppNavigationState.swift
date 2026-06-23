import EMathicaWorkspaceKit
import EMathicaDocumentKit
import Foundation
import Observation

@Observable
final class AppNavigationState {
    var route: AppRoute = .home
    private let projectStore: any ProjectStore

    init(projectStore: (any ProjectStore)? = nil) {
        self.projectStore = projectStore ?? (try? LocalProjectStore()) ?? HomeMockProjectStore()
    }

    func goHome() {
        route = .home
    }

    func openWorkspace(module: CalculatorModuleType, document: EMathicaDocument) {
        route = .workspace(module: module, document: document)
    }

    func saveDocument(_ document: EMathicaDocument) {
        try? projectStore.saveProject(document)
    }

    func renameProject(id: UUID, title: String) throws -> RecentProject {
        try projectStore.renameProject(id: id, title: title)
    }

    func closeWorkspaceSaving(_ document: EMathicaDocument) {
        saveDocument(document)
        goHome()
    }
}

// MARK: - WorkspaceNavigationDelegate

extension AppNavigationState: WorkspaceNavigationDelegate {
    func workspaceDidRequestClose(document: EMathicaDocument) {
        closeWorkspaceSaving(document)
    }

    func workspaceDidRenameProject(id: UUID, title: String) throws -> RecentProject {
        try renameProject(id: id, title: title)
    }
}
