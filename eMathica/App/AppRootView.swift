import SwiftUI
import EMathicaDocumentKit
import EMathicaHomeFeature
import EMathicaWorkspaceKit

struct AppRootView: View {
    @Environment(AppNavigationState.self) private var navigation
    @State private var homeState: CoreHomeState
    #if DEBUG
    @State private var showsPlaceholderComparison = false
    #endif

    init(projectStore: any ProjectStore) {
        let homeModuleCatalog = HomeModuleCatalog(
            modules: CalculatorModuleRegistry.all.map { module in
                HomeModuleDescriptor(
                    id: module.id,
                    title: module.title,
                    subtitle: module.subtitle,
                    iconName: module.iconName
                )
            }
        )
        _homeState = State(
            initialValue: CoreHomeState(
                projectStore: projectStore,
                moduleCatalog: homeModuleCatalog
            )
        )
    }

    private var homeActions: HomeFeatureActions {
        HomeFeatureActions(
            openWorkspace: { request in
                navigation.openWorkspace(
                    module: request.module,
                    document: request.document
                )
            }
        )
    }

    var body: some View {
        Group {
            switch navigation.route {
            case .home:
                homeView
            case .workspace(let module, let document):
                WorkspaceView(
                    module: module,
                    document: document,
                    configuration: workspaceConfiguration(for: module)
                )
            }
        }
    }

    private var homeView: some View {
        let content = CoreHomeView(
                    selectedFilter: Binding(
                        get: { homeState.ui.selectedFilter },
                        set: { homeState.setFilter($0) }
                    ),
                    selectedModuleID: Binding(
                        get: { homeState.ui.selectedModuleID },
                        set: { homeState.ui.selectedModuleID = $0 }
                    ),
                    searchText: Binding(
                        get: { homeState.ui.searchText },
                        set: { homeState.ui.searchText = $0 }
                    ),
                    isSearchPresented: Binding(
                        get: { homeState.ui.isSearchPresented },
                        set: { homeState.ui.isSearchPresented = $0 }
                    ),
                    lastErrorMessage: Binding(
                        get: { homeState.lastErrorMessage },
                        set: { homeState.lastErrorMessage = $0 }
                    ),
                    isSelectionMode: homeState.ui.isSelectionMode,
                    selectedProjectIDs: homeState.ui.selectedProjectIDs,
                    projects: homeState.filteredProjects(),
                    moduleCatalog: homeState.moduleCatalog,
                    previewURLForProjectID: { projectID in
                        homeState.previewURL(for: projectID)
                    },
                    moduleTitleForProjectModuleID: { moduleID in
                        homeState.moduleTitle(for: moduleID)
                    },
                    moduleAccentTokenForProjectModuleID: { moduleID in
                        homeState.moduleAccentToken(for: moduleID)
                    },
                    actions: homeActions,
                    onSelectModule: { moduleID in
                        homeState.selectModule(moduleID: moduleID)
                    },
                    onProjectRenameRequest: { _ in },
                    onRenameProject: { project, title in
                        homeState.renameProject(id: project.id, title: title)
                    },
                    onDeleteSelectedProjects: {
                        homeState.deleteSelectedProjects()
                    },
                    onMoveSelectedProjects: { moduleID in
                        homeState.moveSelectedProjects(to: moduleID)
                    },
                    onClearSelection: {
                        homeState.clearSelection()
                    },
                    onToggleSelectionMode: {
                        homeState.toggleSelectionMode()
                    },
                    onToggleProjectSelection: { projectID in
                        homeState.toggleProjectSelection(id: projectID)
                    },
                    openProjectRequest: { project in
                        let result = try homeState.openProject(project)
                        return HomeWorkspaceOpenRequest(module: result.module, document: result.document)
                    },
                    createProjectRequest: { module in
                        let document = try homeState.createProject(module: module, title: "新项目")
                        return HomeWorkspaceOpenRequest(module: module, document: document)
                    },
                    reloadProjects: {
                        homeState.reloadProjects()
                    }
                )

        #if DEBUG
        return AnyView(
            ZStack(alignment: .bottomTrailing) {
                content
                Menu {
                    Button("Open Valid Formula Rendering Fixture") {
                        openFormulaRenderingBaselineFixture()
                    }
                    Button("Generate Valid Formula Rendering Fixture") {
                        generateFormulaRenderingBaselineFixture()
                    }
                    Button("Placeholder Rendering Comparison") {
                        showsPlaceholderComparison = true
                    }
                } label: {
                    Label("Developer", systemImage: "wrench.and.screwdriver")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: Capsule())
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .accessibilityLabel("开发调试入口")
            }
            .sheet(isPresented: $showsPlaceholderComparison) {
                PlaceholderRenderingComparisonView()
            }
        )
        #else
        return AnyView(content)
        #endif
    }

    private func openFormulaRenderingBaselineFixture() {
        do {
            _ = try FormulaRenderingBaselineFixtureWriter.exportFixtureToSourceTree()
            let projectID = try FormulaRenderingBaselineFixtureImporter.importIntoLocalProjectStore()
            homeState.reloadProjects()
            guard let project = homeState.projects.first(where: { $0.id == projectID }) else {
                homeState.lastErrorMessage = "已导入基准 fixture，但未在最近项目列表中找到。"
                return
            }
            let result = try homeState.openProject(project)
            navigation.openWorkspace(module: result.module, document: result.document)
        } catch {
            homeState.lastErrorMessage = "打开基准 fixture 失败：\(error.localizedDescription)"
        }
    }

    private func generateFormulaRenderingBaselineFixture() {
        do {
            let export = try FormulaRenderingBaselineFixtureWriter.exportFixtureToSourceTree()
            homeState.lastErrorMessage = "已生成合法 fixture：\(export.fixtureURL.path)"
        } catch {
            homeState.lastErrorMessage = "生成合法 fixture 失败：\(error.localizedDescription)"
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
    let projectStore = HomeMockProjectStore()
    AppRootView(projectStore: projectStore)
        .environment(AppNavigationState(projectStore: projectStore))
}
