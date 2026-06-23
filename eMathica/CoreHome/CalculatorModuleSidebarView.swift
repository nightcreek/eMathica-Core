import EMathicaWorkspaceKit
import EMathicaThemeKit
import SwiftUI

struct CalculatorModuleSidebarView: View {
    @Environment(\.colorScheme) private var colorScheme

    let modules: [CalculatorModule]
    let selectedModuleID: String
    let onSelect: (String) -> Void

    var body: some View {
        LiquidGlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(modules) { module in
                    Button {
                        onSelect(module.id.rawValue)
                    } label: {
                        HStack(spacing: 12) {
                            ModuleIconView(
                                iconName: module.iconName,
                                accent: accentToken(for: module).resolvedColor()
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(module.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(primaryText)
                                    .lineLimit(1)

                                Text(module.subtitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(selectionBackground(for: module))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 260)
    }

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.86)
    }

    private func accentToken(for module: CalculatorModule) -> ColorToken {
        switch module.id {
        case .plane:
            return .blue
        case .space:
            return .indigo
        case .modeling:
            return .purple
        case .music:
            return .cyan
        case .data:
            return .green
        case .notes:
            return .pink
        }
    }

    @ViewBuilder
    private func selectionBackground(for module: CalculatorModule) -> some View {
        if selectedModuleID == module.id.rawValue {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.blue.opacity(colorScheme == .dark ? 0.18 : 0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.blue.opacity(colorScheme == .dark ? 0.35 : 0.22), lineWidth: 1)
                }
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.clear)
        }
    }
}
