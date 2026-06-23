import EMathicaWorkspaceKit
import EMathicaThemeKit
import EMathicaDocumentKit
import SwiftUI

struct GalleryDrawerView: View {
    @Environment(AppNavigationState.self) private var navigation
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var state: CoreHomeState

    let drawerHeightFraction: ClosedRange<Double>?
    let fixedHeight: CGFloat?
    let showsSidebar: Bool
    let horizontalPadding: CGFloat
    let cardColumnCount: Int?
    let cardSpacing: CGFloat
    let cardMinWidth: CGFloat?
    let cardMaxWidth: CGFloat?
    let cardHeight: CGFloat?
    let thumbnailHeight: CGFloat?
    let panelCornerRadius: CGFloat?
    let panelPadding: CGFloat?
    let categoryRowHeight: CGFloat?
    let isCompactHeader: Bool
    let bottomPadding: CGFloat

    init(
        state: CoreHomeState,
        drawerHeightFraction: ClosedRange<Double>? = 0.52...0.60,
        fixedHeight: CGFloat? = nil,
        showsSidebar: Bool = true,
        horizontalPadding: CGFloat = 16,
        cardColumnCount: Int? = nil,
        cardSpacing: CGFloat = 18,
        cardMinWidth: CGFloat? = nil,
        cardMaxWidth: CGFloat? = nil,
        cardHeight: CGFloat? = nil,
        thumbnailHeight: CGFloat? = nil,
        panelCornerRadius: CGFloat? = nil,
        panelPadding: CGFloat? = nil,
        categoryRowHeight: CGFloat? = nil,
        isCompactHeader: Bool = false,
        bottomPadding: CGFloat = 14
    ) {
        self.state = state
        self.drawerHeightFraction = drawerHeightFraction
        self.fixedHeight = fixedHeight
        self.showsSidebar = showsSidebar
        self.horizontalPadding = horizontalPadding
        self.cardColumnCount = cardColumnCount
        self.cardSpacing = cardSpacing
        self.cardMinWidth = cardMinWidth
        self.cardMaxWidth = cardMaxWidth
        self.cardHeight = cardHeight
        self.thumbnailHeight = thumbnailHeight
        self.panelCornerRadius = panelCornerRadius
        self.panelPadding = panelPadding
        self.categoryRowHeight = categoryRowHeight
        self.isCompactHeader = isCompactHeader
        self.bottomPadding = bottomPadding
    }

    @State private var renamingProject: RecentProject?
    @State private var renameTitleDraft: String = ""

    var body: some View {
        GeometryReader { proxy in
            let fullHeight = proxy.size.height
            let safeBottom = proxy.safeAreaInsets.bottom
            let targetHeight = fixedHeight ?? (fullHeight * (drawerHeightFraction?.upperBound ?? 0.60))

            VStack(spacing: 0) {
                LiquidGlassPanel(theme: drawerTheme) {
                    VStack(spacing: 12) {
                        drawerHandle

                        GalleryTopBar(
                            state: state,
                            rowHeight: categoryRowHeight,
                            isCompact: isCompactHeader
                        )

                        Divider().opacity(colorScheme == .dark ? 0.22 : 0.40)

                        HStack(alignment: .top, spacing: 18) {
                            if showsSidebar {
                                CalculatorModuleSidebarView(
                                    modules: state.modules,
                                    selectedModuleID: state.ui.selectedModuleID
                                ) { moduleID in
                                    state.selectModule(moduleID: moduleID)
                                }
                                .frame(width: 240)
                            }

                            ScrollView(.vertical, showsIndicators: false) {
                                RecentProjectsGridView(
                                    projects: state.filteredProjects(),
                                    modulesByID: state.modulesByID,
                                    isSelectionMode: state.ui.isSelectionMode,
                                    selectedProjectIDs: state.ui.selectedProjectIDs,
                                    previewURLForProjectID: { state.previewURL(for: $0) },
                                    preferredColumnCount: cardColumnCount,
                                    cardSpacing: cardSpacing,
                                    adaptiveMinWidth: cardMinWidth,
                                    adaptiveMaxWidth: cardMaxWidth,
                                    cardHeight: cardHeight,
                                    thumbnailHeight: thumbnailHeight
                                ) { project in
                                    if state.ui.isSelectionMode {
                                        state.toggleProjectSelection(id: project.id)
                                    } else {
                                        do {
                                            let opened = try state.openProject(project)
                                            navigation.openWorkspace(module: opened.module, document: opened.document)
                                        } catch {
                                            state.lastErrorMessage = "打开项目失败：\(error.localizedDescription)"
                                        }
                                    }
                                } onProjectRenameTap: { project in
                                    renamingProject = project
                                    renameTitleDraft = project.title
                                }

                                if !state.ui.isSelectionMode {
                                    footerText
                                        .padding(.top, 8)
                                        .padding(.bottom, 12)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                        if state.ui.isSelectionMode {
                            GalleryBatchActionBar(state: state)
                        }
                    }
                }
            }
            .frame(height: targetHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, safeBottom + bottomPadding)
            .sheet(item: $renamingProject) { project in
                RenameProjectSheet(
                    initialTitle: project.title,
                    onCancel: {
                        renamingProject = nil
                        renameTitleDraft = ""
                    },
                    onSave: { newTitle in
                        state.renameProject(id: project.id, title: newTitle)
                        renamingProject = nil
                        renameTitleDraft = ""
                    }
                )
            }
        }
    }

    private var drawerTheme: LiquidGlassTheme {
        var t = LiquidGlassTheme()
        t.panelCornerRadius = panelCornerRadius ?? 34
        t.panelPadding = panelPadding ?? 16
        return t
    }

    private var drawerHandle: some View {
        Capsule(style: .continuous)
            .fill(Color.white.opacity(colorScheme == .dark ? 0.22 : 0.38))
            .frame(width: 48, height: 5)
            .padding(.top, 2)
            .padding(.bottom, 2)
    }

    private var footerText: some View {
        Text("按最近更新排序")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

private struct RenameProjectSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialTitle: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    @State private var titleDraft: String
    @FocusState private var isTitleFocused: Bool

    init(
        initialTitle: String,
        onCancel: @escaping () -> Void,
        onSave: @escaping (String) -> Void
    ) {
        self.initialTitle = initialTitle
        self.onCancel = onCancel
        self.onSave = onSave
        _titleDraft = State(initialValue: initialTitle)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("输入新的项目名称")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("项目名称", text: $titleDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("重命名项目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isTitleFocused = true
                }
            }
        }
    }

    private func save() {
        onSave(titleDraft)
        dismiss()
    }
}

private struct GalleryTopBar: View {
    @Bindable var state: CoreHomeState
    let rowHeight: CGFloat?
    let isCompact: Bool

    var body: some View {
        VStack(spacing: isCompact ? 8 : 10) {
            HStack(spacing: 12) {
                GalleryTabBar(selectedFilter: Binding(
                    get: { state.ui.selectedFilter },
                    set: { state.setFilter($0) }
                ))

                Spacer(minLength: 0)

                Button(state.ui.isSelectionMode ? "完成" : "选择") {
                    state.toggleSelectionMode()
                }
                .buttonStyle(.bordered)

                Button {
                    withAnimation(.snappy(duration: 0.20)) {
                        state.ui.isSearchPresented.toggle()
                        if !state.ui.isSearchPresented {
                            state.ui.searchText = ""
                        }
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.bordered)
            }
            .controlSize(isCompact ? .small : .regular)
            .frame(minHeight: rowHeight ?? 40)

            if state.ui.isSearchPresented {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("搜索 .emathica 文件名", text: Binding(
                        get: { state.ui.searchText },
                        set: { state.ui.searchText = $0 }
                    ))
                    .textFieldStyle(.plain)

                    Button {
                        state.ui.searchText = ""
                        state.ui.isSearchPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}

private struct GalleryBatchActionBar: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var state: CoreHomeState

    @State private var isShowingDeleteAlert: Bool = false
    @State private var isShowingMoveSheet: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text("已选 \(state.ui.selectedProjectIDs.count) 项")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Button(role: .destructive) {
                isShowingDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
            .buttonStyle(.bordered)

            Button {
                isShowingMoveSheet = true
            } label: {
                Label("移动", systemImage: "folder")
            }
            .buttonStyle(.bordered)

            Button {
                state.clearSelection()
            } label: {
                Label("取消", systemImage: "xmark")
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.regular)
        .padding(.top, 2)
        .alert("删除项目", isPresented: $isShowingDeleteAlert) {
            Button("删除", role: .destructive) {
                state.deleteSelectedProjects()
                state.toggleSelectionMode()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("第一版为 mock 删除（仅内存移除）。后续会对 .emathica 包进行真实删除。")
        }
        .sheet(isPresented: $isShowingMoveSheet) {
            MoveDestinationSheet(modules: state.modules) { moduleID in
                state.moveSelectedProjects(to: moduleID)
                state.toggleSelectionMode()
                isShowingMoveSheet = false
            }
        }
        .tint(colorScheme == .dark ? .white : .primary)
    }
}

private struct MoveDestinationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let modules: [CalculatorModule]
    let onMove: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("移动到") {
                    ForEach(modules) { module in
                        Button {
                            onMove(module.id.rawValue)
                        } label: {
                            HStack(spacing: 12) {
                                ModuleAssetIconView(moduleID: module.id.rawValue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(module.title)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(module.subtitle)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("移动项目")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
