import SwiftUI

struct CoreHomeView: View {
    @Environment(AppNavigationState.self) private var navigation

    @State private var state = CoreHomeState()
    @State private var isShowingNewProjectPicker: Bool = false

    var body: some View {
        CoreHomeResponsiveContainer(
            state: state,
            onPrimaryAction: { isShowingNewProjectPicker = true },
            onSecondaryAction: {
                // TODO: formula rewrite + notes
            }
        )
        .sheet(isPresented: $isShowingNewProjectPicker) {
            NewProjectTypePickerView { module in
                do {
                    let document = try state.createProject(module: module, title: "新项目")
                    navigation.openWorkspace(module: module, document: document)
                } catch {
                    state.lastErrorMessage = "新建项目失败：\(error.localizedDescription)"
                }
                isShowingNewProjectPicker = false
            }
        }
        .task {
            state.reloadProjects()
        }
    }
}

#Preview {
    CoreHomeView()
}
