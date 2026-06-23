import EMathicaWorkspaceKit
import Foundation

enum PlaneToolProvider {
    static func defaultToolGroups() -> [WorkspaceToolGroup] {
        [
            WorkspaceToolGroup(
                id: "plane.selection",
                title: "选择",
                tools: [
                    WorkspaceTool(
                        id: PlaneToolIDs.select,
                        title: "光标",
                        icon: .system("cursorarrow"),
                        action: .setActiveTool(PlaneToolIDs.select)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.pan,
                        title: "平移",
                        icon: .system("hand.draw"),
                        action: .setActiveTool(PlaneToolIDs.pan)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.delete,
                        title: "删除",
                        icon: .system("trash"),
                        action: .setActiveTool(PlaneToolIDs.delete)
                    )
                ]
            ),
            WorkspaceToolGroup(
                id: "plane.geometry",
                title: "几何",
                tools: [
                    WorkspaceTool(
                        id: PlaneToolIDs.point,
                        title: "点",
                        icon: .geometry(.point),
                        action: .setActiveTool(PlaneToolIDs.point)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.segment,
                        title: "线段",
                        icon: .geometry(.segment),
                        action: .setActiveTool(PlaneToolIDs.segment)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.midpoint,
                        title: "中点",
                        icon: .geometry(.midpoint),
                        action: .setActiveTool(PlaneToolIDs.midpoint)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.line,
                        title: "直线",
                        icon: .geometry(.line),
                        action: .setActiveTool(PlaneToolIDs.line)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.ray,
                        title: "射线",
                        icon: .geometry(.ray),
                        action: .setActiveTool(PlaneToolIDs.ray)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.parallel,
                        title: "平行线",
                        icon: .geometry(.parallel),
                        action: .setActiveTool(PlaneToolIDs.parallel)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.perpendicular,
                        title: "垂线",
                        icon: .geometry(.perpendicular),
                        action: .setActiveTool(PlaneToolIDs.perpendicular)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.circle,
                        title: "圆",
                        icon: .geometry(.circle),
                        action: .setActiveTool(PlaneToolIDs.circle)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.arc,
                        title: "圆弧",
                        icon: .geometry(.arc),
                        action: .setActiveTool(PlaneToolIDs.arc)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.intersection,
                        title: "交点",
                        icon: .geometry(.intersection),
                        action: .setActiveTool(PlaneToolIDs.intersection)
                    )
                ]
            ),
            WorkspaceToolGroup(
                id: "plane.function",
                title: "函数",
                tools: [
                    WorkspaceTool(
                        id: PlaneToolIDs.function,
                        title: "函数",
                        icon: .text("f(x)"),
                        action: .setActiveTool(PlaneToolIDs.function)
                    ),
                    WorkspaceTool(
                        id: PlaneToolIDs.slider,
                        title: "滑块",
                        icon: .system("slider.horizontal.3"),
                        action: .setActiveTool(PlaneToolIDs.slider)
                    )
                ]
            )
        ]
    }
}
