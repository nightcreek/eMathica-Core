import SwiftUI

struct SpaceCalculatorPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("立体计算器", systemImage: "cube.transparent", description: Text("第一版暂为占位，后续接入统一 WorkspaceKit。"))
    }
}
