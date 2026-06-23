import SwiftUI

struct GalleryTabBar: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selectedFilter: GalleryFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GalleryFilter.allCases) { filter in
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selectedFilter == filter ? Color.white : unselectedText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                if selectedFilter == filter {
                                    Capsule(style: .continuous)
                                        .fill(Color.blue.opacity(0.92))
                                } else {
                                    Capsule(style: .continuous)
                                        .fill(Color.clear)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var unselectedText: Color {
        colorScheme == .dark ? Color.white.opacity(0.70) : Color.black.opacity(0.62)
    }
}
