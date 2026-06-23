import SwiftUI

struct MusicPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("音乐", systemImage: "waveform", description: Text("第一版暂为占位。"))
    }
}
