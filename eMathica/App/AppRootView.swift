import SwiftUI
import EMathicaDocumentKit
import EMathicaWorkspaceKit

struct AppRootView: View {
    @Environment(AppNavigationState.self) private var navigation

    var body: some View {
        Group {
            switch navigation.route {
            case .home:
                CoreHomeView()
            case .workspace(let module, let document):
                WorkspaceView(
                    module: module,
                    document: document,
                    configuration: workspaceConfiguration(for: module)
                )
            }
        }
    }

    private func workspaceConfiguration(for module: CalculatorModuleType) -> WorkspaceConfiguration {
        let moduleProvider = CalculatorModuleRegistry.moduleProvider(for: module)
        return WorkspaceConfiguration(
            module: module,
            moduleProvider: moduleProvider,
            toolGroups: moduleProvider.toolGroups
        )
    }
}

#Preview {
    AppRootView()
        .environment(AppNavigationState())
}
