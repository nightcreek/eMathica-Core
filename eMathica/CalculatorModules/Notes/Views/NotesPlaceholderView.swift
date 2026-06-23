import SwiftUI

struct NotesPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("笔记与公式", systemImage: "note.text", description: Text("第一版暂为占位。"))
    }
}
