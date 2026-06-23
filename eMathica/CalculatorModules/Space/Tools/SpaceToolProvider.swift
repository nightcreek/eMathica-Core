import EMathicaWorkspaceKit
import Foundation

enum SpaceToolProvider {
    static func defaultToolGroups() -> [WorkspaceToolGroup] {
        [
            WorkspaceToolGroup(
                id: "space.navigation",
                title: "导航",
                tools: [
                    WorkspaceTool(
                        id: SpaceToolIDs.select,
                        title: "选择",
                        icon: .system("cursorarrow"),
                        action: .setActiveTool(SpaceToolIDs.select)
                    ),
                    WorkspaceTool(
                        id: SpaceToolIDs.orbit,
                        title: "旋转",
                        icon: .system("rotate.3d"),
                        action: .setActiveTool(SpaceToolIDs.orbit)
                    ),
                    WorkspaceTool(
                        id: SpaceToolIDs.pan,
                        title: "平移",
                        icon: .system("hand.draw"),
                        action: .setActiveTool(SpaceToolIDs.pan)
                    )
                ]
            ),
            WorkspaceToolGroup(
                id: "space.geometry",
                title: "几何",
                tools: [
                    WorkspaceTool(
                        id: SpaceToolIDs.point3D,
                        title: "点3D",
                        icon: .system("point.3.connected.trianglepath.dotted"),
                        action: .setActiveTool(SpaceToolIDs.point3D)
                    ),
                    WorkspaceTool(
                        id: SpaceToolIDs.segment3D,
                        title: "线段3D",
                        icon: .system("line.diagonal"),
                        action: .setActiveTool(SpaceToolIDs.segment3D)
                    ),
                    WorkspaceTool(
                        id: SpaceToolIDs.line3D,
                        title: "直线3D",
                        icon: .system("arrow.left.and.right"),
                        action: .setActiveTool(SpaceToolIDs.line3D)
                    ),
                    WorkspaceTool(
                        id: SpaceToolIDs.plane3D,
                        title: "平面3D",
                        icon: .system("square.split.diagonal.2x2"),
                        action: .setActiveTool(SpaceToolIDs.plane3D)
                    )
                ]
            )
        ]
    }
}
