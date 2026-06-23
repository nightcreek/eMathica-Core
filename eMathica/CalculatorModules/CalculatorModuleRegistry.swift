import EMathicaWorkspaceKit
import Foundation

enum CalculatorModuleRegistry {
    static let all: [CalculatorModule] = [
        CalculatorModule(id: .plane, title: "平面计算器", subtitle: "函数与几何", iconName: "plane_calculator"),
        CalculatorModule(id: .space, title: "立体计算器", subtitle: "图形与几何", iconName: "space_calculator"),
        CalculatorModule(id: .modeling, title: "建模", subtitle: "几何建模与可视化", iconName: "modeling"),
        CalculatorModule(id: .music, title: "音乐", subtitle: "乐器创作与演奏", iconName: "music"),
        CalculatorModule(id: .data, title: "数据分析", subtitle: "数据处理与可视化", iconName: "data_analysis"),
        CalculatorModule(id: .notes, title: "笔记与公式", subtitle: "公式笔记与整理", iconName: "notes_formula")
    ]

    static func module(for id: CalculatorModuleType) -> CalculatorModule {
        all.first(where: { $0.id == id }) ?? all[0]
    }

    static func toolGroups(for id: CalculatorModuleType) -> [WorkspaceToolGroup] {
        moduleProvider(for: id).toolGroups
    }

    static func moduleProvider(for id: CalculatorModuleType) -> WorkspaceModuleProviding {
        switch id {
        case .plane:
            return PlaneWorkspaceModuleProvider()
        case .space:
            return SpaceWorkspaceModuleProvider()
        case .modeling, .music, .data, .notes:
            return DefaultWorkspaceModuleProvider(module: id, toolGroups: defaultToolGroups())
        }
    }

    private static func defaultToolGroups() -> [WorkspaceToolGroup] {
        [
            WorkspaceToolGroup(
                id: "common.selection",
                title: "选择",
                tools: [
                    WorkspaceTool(
                        id: "common.select",
                        title: "光标",
                        icon: .system("cursorarrow"),
                        action: .setActiveTool("common.select")
                    ),
                    WorkspaceTool(
                        id: "common.pan",
                        title: "平移",
                        icon: .system("hand.draw"),
                        action: .setActiveTool("common.pan")
                    )
                ]
            )
        ]
    }
}
