import Foundation

struct CoreHomeUIState: Hashable, Codable {
    var selectedFilter: GalleryFilter
    var selectedModuleID: String
    var isSelectionMode: Bool
    var selectedProjectIDs: Set<UUID>
    var searchText: String
    var isSearchPresented: Bool

    static let `default` = CoreHomeUIState(
        selectedFilter: .recent,
        selectedModuleID: "plane",
        isSelectionMode: false,
        selectedProjectIDs: [],
        searchText: "",
        isSearchPresented: false
    )
}
