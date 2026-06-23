import SwiftUI
import EMathicaWorkspaceKit

@main
struct EMathicaApp: App {
    private let navigation = AppNavigationState()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(navigation)
                .environment(\.workspaceNavigationDelegate, navigation)
        }
    }
}
