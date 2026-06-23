import SwiftUI

struct DataPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("数据分析", systemImage: "chart.bar", description: Text("第一版暂为占位。"))
    }
}
