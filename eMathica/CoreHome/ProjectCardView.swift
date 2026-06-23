import EMathicaDocumentKit
import SwiftUI

struct ProjectCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let project: RecentProject
    let moduleTitle: String
    let accent: Color
    let previewURL: URL?
    let isSelectionMode: Bool
    let isSelected: Bool
    let cardHeight: CGFloat?
    let thumbnailHeight: CGFloat?
    let action: () -> Void
    let onRename: (() -> Void)?

    init(
        project: RecentProject,
        moduleTitle: String,
        accent: Color,
        previewURL: URL?,
        isSelectionMode: Bool,
        isSelected: Bool,
        cardHeight: CGFloat? = nil,
        thumbnailHeight: CGFloat? = nil,
        action: @escaping () -> Void,
        onRename: (() -> Void)? = nil
    ) {
        self.project = project
        self.moduleTitle = moduleTitle
        self.accent = accent
        self.previewURL = previewURL
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
        self.cardHeight = cardHeight
        self.thumbnailHeight = thumbnailHeight
        self.action = action
        self.onRename = onRename
    }

    private var thumbnailKind: ProjectThumbnailKind {
        ProjectThumbnailKind(rawValue: project.thumbnailKindRawValue) ?? .parabolaGraph
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 10) {
                    ProjectThumbnailView(kind: thumbnailKind, accent: accent, previewURL: previewURL)
                        .frame(height: thumbnailHeight ?? 114)
                        .overlay(alignment: .topTrailing) {
                            if isSelectionMode {
                                selectionBadge(isSelected: isSelected)
                                    .padding(10)
                            }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .lineLimit(1)

                        Text(moduleTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(project.modifiedDateText)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.secondary.opacity(0.9))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 2)
                }
                .padding(12)
                .frame(minHeight: cardHeight ?? 176, alignment: .top)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                if !isSelectionMode {
                    Button("重命名", systemImage: "pencil") {
                        onRename?()
                    }
                }
            }

            if !isSelectionMode, let onRename {
                Menu {
                    Button("重命名", systemImage: "pencil", action: onRename)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.88) : .black.opacity(0.72))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(10)
                .accessibilityLabel("项目操作")
                .accessibilityHint("打开项目菜单")
                .zIndex(2)
            }
        }
        .onChange(of: isSelectionMode) { _, newValue in
            if newValue {
                // no-op: keep card action behavior unchanged in selection mode
                _ = ()
            }
        }
    }

    private func selectionBadge(isSelected: Bool) -> some View {
        Circle()
            .fill(isSelected ? Color.blue.opacity(0.92) : (colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.08)))
            .frame(width: 22, height: 22)
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.22), lineWidth: 1)
                        .padding(5)
                }
            }
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    private var borderColor: Color {
        if isSelected {
            return Color.blue.opacity(colorScheme == .dark ? 0.75 : 0.55)
        }
        return colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let tint: Color = {
            if colorScheme == .dark {
                return Color(red: 0.10, green: 0.14, blue: 0.26).opacity(0.58)
            }
            return Color.white.opacity(0.72)
        }()

        if #available(iOS 26.0, macOS 16.0, *) {
            Color.clear
                .glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: 18))
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(tint)
                }
        }
    }
}
