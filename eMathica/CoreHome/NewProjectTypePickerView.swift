import EMathicaWorkspaceKit
import SwiftUI

struct NewProjectTypePickerView: View {
    @Environment(\.dismiss) private var dismiss

    let onPick: (CalculatorModuleType) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("选择模块") {
                    ForEach(CalculatorModuleType.allCases) { module in
                        let info = CalculatorModuleRegistry.module(for: module)
                        Button {
                            onPick(module)
                        } label: {
                            HStack(spacing: 12) {
                                ModuleIconView(iconName: info.iconName, accent: .blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(info.title)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(info.subtitle)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("创建作品")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
