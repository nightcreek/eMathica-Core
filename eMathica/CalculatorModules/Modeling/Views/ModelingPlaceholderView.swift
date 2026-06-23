import SwiftUI

struct ModelingPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("建模", systemImage: "cube", description: Text("第一版暂为占位。"))
    }
}
