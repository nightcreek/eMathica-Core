import EMathicaWorkspaceKit
import EMathicaThemeKit
import EMathicaDocumentKit
import SwiftUI

struct PhoneCoreHomeLayout: View {
    @Environment(AppNavigationState.self) private var navigation
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var state: CoreHomeState
    let metrics: CoreHomeLayoutMetrics
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    private struct PhonePortraitMetrics {
        let phoneTitleFontSize: CGFloat
        let phoneHeroHeight: CGFloat
        let phoneHeroTopPadding: CGFloat
        let titleToButtonsSpacing: CGFloat
        let phoneButtonSpacing: CGFloat
        let phonePrimaryButtonHeight: CGFloat
        let phoneSecondaryButtonHeight: CGFloat
        let phoneButtonFontSize: CGFloat
        let phoneActionsToCategorySpacing: CGFloat
        let phoneCategoryToRecentSpacing: CGFloat
        let phoneRecentToResourceSpacing: CGFloat
        let contentTopPadding: CGFloat
        let contentBottomPadding: CGFloat

        static func resolve(size: CGSize, safeAreaInsets: EdgeInsets) -> PhonePortraitMetrics {
            let width = max(1, size.width)
            let height = max(1, size.height)
            let safeBottom = safeAreaInsets.bottom

            let phoneTitleFontSize = clamp(width * 0.155, min: 56, max: 68)
            let phoneHeroHeight = clamp(height * 0.23, min: 190, max: 245)
            let phoneHeroTopPadding = clamp(height * 0.085, min: 72, max: 104)
            let titleToButtonsSpacing = clamp(height * 0.032, min: 28, max: 40)
            let phoneButtonSpacing = clamp(height * 0.012, min: 10, max: 12)
            let phonePrimaryButtonHeight = clamp(height * 0.063, min: 52, max: 56)
            let phoneSecondaryButtonHeight = clamp(height * 0.058, min: 48, max: 52)
            let phoneButtonFontSize = clamp(width * 0.043, min: 15, max: 17)
            let phoneActionsToCategorySpacing = clamp(height * 0.020, min: 16, max: 22)
            let phoneCategoryToRecentSpacing = clamp(height * 0.014, min: 10, max: 14)
            let phoneRecentToResourceSpacing = clamp(height * 0.020, min: 16, max: 22)
            let contentTopPadding = 0 as CGFloat
            let contentBottomPadding = max(12, safeBottom + 8)

            return PhonePortraitMetrics(
                phoneTitleFontSize: phoneTitleFontSize,
                phoneHeroHeight: phoneHeroHeight,
                phoneHeroTopPadding: phoneHeroTopPadding,
                titleToButtonsSpacing: titleToButtonsSpacing,
                phoneButtonSpacing: phoneButtonSpacing,
                phonePrimaryButtonHeight: phonePrimaryButtonHeight,
                phoneSecondaryButtonHeight: phoneSecondaryButtonHeight,
                phoneButtonFontSize: phoneButtonFontSize,
                phoneActionsToCategorySpacing: phoneActionsToCategorySpacing,
                phoneCategoryToRecentSpacing: phoneCategoryToRecentSpacing,
                phoneRecentToResourceSpacing: phoneRecentToResourceSpacing,
                contentTopPadding: contentTopPadding,
                contentBottomPadding: contentBottomPadding
            )
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            ZStack {
                CoreHeroBackgroundView()
                    .opacity(0.95)

                if metrics.profile == .phoneLandscape {
                    phoneLandscapeContent(size: proxy.size, insets: insets)
                } else {
                    let portraitMetrics = PhonePortraitMetrics.resolve(size: proxy.size, safeAreaInsets: insets)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            phoneHeroHeader(containerSize: proxy.size, portraitMetrics: portraitMetrics)
                            phonePrimaryActions(portraitMetrics: portraitMetrics)
                                .padding(.top, portraitMetrics.titleToButtonsSpacing)
                            phoneModuleChips
                                .padding(.top, portraitMetrics.phoneActionsToCategorySpacing)
                            phoneRecentProjectsSection(width: proxy.size.width)
                                .padding(.top, portraitMetrics.phoneCategoryToRecentSpacing)
                            phoneResourceSection
                                .padding(.top, portraitMetrics.phoneRecentToResourceSpacing)
                        }
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.top, portraitMetrics.contentTopPadding)
                        .padding(.bottom, portraitMetrics.contentBottomPadding)
                    }
                }
            }
        }
    }

    private func phoneLandscapeContent(size: CGSize, insets: EdgeInsets) -> some View {
        let leftPadding = insets.leading + 18
        let rightPadding = insets.trailing + 18
        let topPadding = insets.top + 12
        let bottomPadding = insets.bottom + 12
        let availableHeight = max(0, size.height - topPadding - bottomPadding)
        let leftWidth = min(max(size.width * 0.35, 300), size.width * 0.38)
        let rightWidth = max(0, size.width - leftPadding - rightPadding - leftWidth - 16)

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("eMathica")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.08, green: 0.12, blue: 0.22))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 6)

                VStack(spacing: 10) {
                    LiquidGlassButton("创建作品", systemImage: "plus", kind: .primary, action: onPrimaryAction)
                        .frame(height: 44)
                    LiquidGlassButton("公式转写与笔记", systemImage: "pencil.and.scribble", kind: .secondary, action: onSecondaryAction)
                        .frame(height: 42)
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
            }
            .frame(width: leftWidth, height: availableHeight, alignment: .topLeading)

            LiquidGlassPanel(theme: landscapePanelTheme) {
                VStack(alignment: .leading, spacing: 10) {
                    landscapeTopBar
                    landscapeProjectsGrid(width: rightWidth)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(width: rightWidth, height: availableHeight)
        }
        .padding(.leading, leftPadding)
        .padding(.trailing, rightPadding)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }

    private func phoneHeroHeader(containerSize: CGSize, portraitMetrics: PhonePortraitMetrics) -> some View {
        return VStack(spacing: 0) {
            Text("eMathica")
                .font(.system(size: portraitMetrics.phoneTitleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.08, green: 0.12, blue: 0.22))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .frame(height: portraitMetrics.phoneHeroHeight, alignment: .top)
        .padding(.top, portraitMetrics.phoneHeroTopPadding)
    }

    private func phonePrimaryActions(portraitMetrics: PhonePortraitMetrics) -> some View {
        VStack(spacing: portraitMetrics.phoneButtonSpacing) {
            LiquidGlassButton("创建作品", systemImage: "plus", kind: .primary, action: onPrimaryAction)
                .font(.system(size: portraitMetrics.phoneButtonFontSize, weight: .semibold))
                .frame(height: portraitMetrics.phonePrimaryButtonHeight)
            LiquidGlassButton("公式转写与笔记", systemImage: "pencil.and.scribble", kind: .secondary, action: onSecondaryAction)
                .font(.system(size: portraitMetrics.phoneButtonFontSize, weight: .semibold))
                .frame(height: portraitMetrics.phoneSecondaryButtonHeight)
        }
    }

    private var phoneModuleChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(moduleFilters) { filter in
                    let isSelected = state.ui.selectedFilter == filter
                    Button {
                        state.setFilter(filter)
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.white : (colorScheme == .dark ? Color.white.opacity(0.76) : Color.black.opacity(0.68)))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(isSelected ? Color.blue.opacity(0.92) : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.42))
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var phoneResourceSection: some View {
        let resources: [(String, String)] = [
            ("示例库", "book.pages"),
            ("模板库", "square.stack.3d.up"),
            ("插件索引", "puzzlepiece.extension"),
            ("开源社区", "person.3")
        ]
        return LiquidGlassPanel(theme: phonePanelTheme) {
            VStack(alignment: .leading, spacing: 10) {
                Text("资源入口")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.9))
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: 90), spacing: 8),
                        GridItem(.flexible(minimum: 90), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(resources, id: \.0) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.1)
                                .font(.system(size: 13, weight: .semibold))
                            Text(item.0)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(.primary.opacity(0.88))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.34))
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                }
            }
        }
    }

    private func phoneRecentProjectsSection(width: CGFloat) -> some View {
        let projects = state.filteredProjects()
        let columns = phoneGridColumns(for: width)

        return LiquidGlassPanel(theme: phonePanelTheme) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("最近使用")
                        .font(.system(size: 18, weight: .bold))

                    Spacer(minLength: 0)

                    Button(state.ui.isSelectionMode ? "完成" : "选择") {
                        state.toggleSelectionMode()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
                            state.ui.isSearchPresented.toggle()
                            if !state.ui.isSearchPresented {
                                state.ui.searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("查看全部") {
                        state.setFilter(.recent)
                        state.ui.searchText = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                if state.ui.isSearchPresented {
                    HStack(spacing: 8) {
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
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                LazyVGrid(columns: columns, spacing: metrics.cardSpacing) {
                    ForEach(projects) { project in
                        let module = state.modulesByID[project.moduleID]
                        let accent = state.moduleAccentToken(for: project.moduleID).resolvedColor()
                        ProjectCardView(
                            project: project,
                            moduleTitle: module?.title ?? "",
                            accent: accent,
                            previewURL: state.previewURL(for: project.id),
                            isSelectionMode: state.ui.isSelectionMode,
                            isSelected: state.ui.selectedProjectIDs.contains(project.id),
                            action: {
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
                        },
                            onRename: nil
                        )
                        .frame(maxWidth: .infinity)
                    }
                }

                if projects.isEmpty {
                    Text("暂无项目")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    private func phoneGridColumns(for width: CGFloat) -> [GridItem] {
        let count: Int
        switch metrics.profile {
        case .phoneLandscape:
            count = 3
        case .phonePortrait:
            count = width < 375 ? 1 : 2
        default:
            count = 2
        }
        return Array(
            repeating: GridItem(.flexible(minimum: 146, maximum: .infinity), spacing: metrics.cardSpacing, alignment: .top),
            count: count
        )
    }

    private func landscapeGridColumns(for width: CGFloat) -> [GridItem] {
        let count = width < 520 ? 2 : 3
        return Array(
            repeating: GridItem(.flexible(minimum: 128, maximum: .infinity), spacing: 10, alignment: .top),
            count: count
        )
    }

    private var landscapeTopBar: some View {
        HStack(spacing: 10) {
            GalleryTabBar(selectedFilter: Binding(
                get: { state.ui.selectedFilter },
                set: { state.setFilter($0) }
            ))
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(state.ui.isSelectionMode ? "完成" : "选择") {
                state.toggleSelectionMode()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    state.ui.isSearchPresented.toggle()
                    if !state.ui.isSearchPresented {
                        state.ui.searchText = ""
                    }
                }
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func landscapeProjectsGrid(width: CGFloat) -> some View {
        let projects = state.filteredProjects()
        return ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: landscapeGridColumns(for: width), spacing: 10) {
                ForEach(projects) { project in
                    let module = state.modulesByID[project.moduleID]
                    let accent = state.moduleAccentToken(for: project.moduleID).resolvedColor()
                    ProjectCardView(
                        project: project,
                        moduleTitle: module?.title ?? "",
                        accent: accent,
                        previewURL: state.previewURL(for: project.id),
                        isSelectionMode: state.ui.isSelectionMode,
                        isSelected: state.ui.selectedProjectIDs.contains(project.id),
                        action: {
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
                        },
                        onRename: nil
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 138)
                }
            }

            if projects.isEmpty {
                Text("暂无项目")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
        }
    }

    private var moduleFilters: [GalleryFilter] {
        GalleryFilter.allCases
    }

    private var phonePanelTheme: LiquidGlassTheme {
        var theme = LiquidGlassTheme()
        theme.panelCornerRadius = 24
        theme.panelPadding = 14
        return theme
    }

    private var landscapePanelTheme: LiquidGlassTheme {
        var theme = LiquidGlassTheme()
        theme.panelCornerRadius = 30
        theme.panelPadding = 16
        return theme
    }
}
