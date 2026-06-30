import SwiftUI
import EMathicaDocumentKit
import EMathicaWorkspaceKit

@main
struct EMathicaApp: App {
    private let projectStore: any ProjectStore
    private let navigation: AppNavigationState

    init() {
        do {
            let store = try LocalProjectStore(previewRenderer: { ProjectPreviewRenderer.renderPNGData(for: $0) })
            self.projectStore = store
            self.navigation = AppNavigationState(projectStore: store)
        } catch {
            fatalError("Failed to create LocalProjectStore: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(projectStore: projectStore)
                .environment(navigation)
                .environment(\.workspaceNavigationDelegate, navigation)
        }
    }
}
