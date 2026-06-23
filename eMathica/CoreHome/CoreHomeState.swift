import EMathicaWorkspaceKit
import EMathicaThemeKit
import EMathicaDocumentKit
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class CoreHomeState {
    var ui: CoreHomeUIState

    let modules: [CalculatorModule]
    private let projectStore: any ProjectStore
    var projects: [RecentProject]
    var lastErrorMessage: String?

    init(
        modules: [CalculatorModule]? = nil,
        projectStore: (any ProjectStore)? = nil,
        ui: CoreHomeUIState? = nil
    ) {
        self.modules = modules ?? CalculatorModuleRegistry.all
        self.projectStore = projectStore ?? (try? LocalProjectStore()) ?? HomeMockProjectStore()
        self.projects = []
        self.ui = ui ?? .default
        self.lastErrorMessage = nil

        if self.ui.selectedModuleID.isEmpty {
            self.ui.selectedModuleID = "plane"
        }
    }

    var modulesByID: [String: CalculatorModule] {
        Dictionary(uniqueKeysWithValues: modules.map { ($0.id.rawValue, $0) })
    }

    func moduleTitle(for moduleID: String) -> String {
        modulesByID[moduleID]?.title ?? ""
    }

    func moduleIconName(for moduleID: String) -> String {
        modulesByID[moduleID]?.iconName ?? "plane_calculator"
    }

    func moduleAccentToken(for moduleID: String) -> ColorToken {
        switch moduleID {
        case "plane":
            return .blue
        case "space":
            return .indigo
        case "modeling":
            return .purple
        case "music":
            return .cyan
        case "data":
            return .green
        case "notes":
            return .pink
        default:
            return .blue
        }
    }

    func filteredProjects() -> [RecentProject] {
        var result = projects

        if let moduleID = ui.selectedFilter.moduleID {
            result = result.filter { $0.moduleID == moduleID }
        }

        let trimmed = ui.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
        }

        return Array(result.prefix(10))
    }

    func setFilter(_ filter: GalleryFilter) {
        withAnimation(.snappy(duration: 0.22)) {
            ui.selectedFilter = filter
            if let moduleID = filter.moduleID {
                ui.selectedModuleID = moduleID
            }
        }
    }

    func selectModule(moduleID: String) {
        withAnimation(.snappy(duration: 0.22)) {
            ui.selectedModuleID = moduleID
            ui.selectedFilter = GalleryFilter.allCases.first(where: { $0.moduleID == moduleID }) ?? .recent
        }
    }

    func toggleSelectionMode() {
        withAnimation(.snappy(duration: 0.20)) {
            ui.isSelectionMode.toggle()
            if !ui.isSelectionMode {
                ui.selectedProjectIDs.removeAll()
            }
        }
    }

    func toggleProjectSelection(id: UUID) {
        if ui.selectedProjectIDs.contains(id) {
            ui.selectedProjectIDs.remove(id)
        } else {
            ui.selectedProjectIDs.insert(id)
        }
    }

    func clearSelection() {
        ui.selectedProjectIDs.removeAll()
    }

    func deleteSelectedProjects() {
        let ids = ui.selectedProjectIDs
        do {
            for id in ids {
                try projectStore.deleteProject(id: id)
            }
            reloadProjects()
        } catch {
            lastErrorMessage = "删除项目失败：\(error.localizedDescription)"
        }
        clearSelection()
    }

    func moveSelectedProjects(to moduleID: String) {
        let ids = ui.selectedProjectIDs
        do {
            for id in ids {
                var document = try projectStore.loadProject(id: id)
                var metadata = document.metadata
                metadata.moduleID = moduleID
                metadata.calculatorType = moduleID
                metadata.updatedAt = Date()
                document.metadata = metadata
                document.moduleID = moduleID
                try projectStore.saveProject(document)
            }
            reloadProjects()
        } catch {
            lastErrorMessage = "移动项目失败：\(error.localizedDescription)"
        }
        clearSelection()
    }

    func reloadProjects() {
        do {
            projects = try projectStore.listProjects()
            lastErrorMessage = nil
        } catch {
            projects = []
            lastErrorMessage = "读取项目列表失败：\(error.localizedDescription)"
        }
    }

    func createProject(module: CalculatorModuleType, title: String = "新项目") throws -> EMathicaDocument {
        let now = Date()
        let projectID = UUID()
        let metadata = ProjectMetadata(
            id: projectID,
            title: title,
            moduleID: module.rawValue,
            createdAt: now,
            updatedAt: now,
            calculatorType: module.rawValue
        )
        let document: EMathicaDocument
        switch module {
        case .plane:
            document = EMathicaDocument(id: projectID, metadata: metadata, moduleID: module.rawValue, objects: PlaneModule.emptyObjects())
        default:
            document = EMathicaDocument(id: projectID, metadata: metadata, moduleID: module.rawValue, objects: [])
        }
        _ = try projectStore.createProject(metadata: metadata, document: document)
        reloadProjects()
        return document
    }

    func openProject(_ project: RecentProject) throws -> (module: CalculatorModuleType, document: EMathicaDocument) {
        let module = CalculatorModuleType(rawValue: project.moduleID) ?? .plane
        var document = try projectStore.loadProject(id: project.id)
        var metadata = document.metadata
        metadata.updatedAt = Date()
        document.metadata = metadata
        do {
            try projectStore.saveProject(document)
            reloadProjects()
        } catch {
            lastErrorMessage = "更新最近使用失败：\(error.localizedDescription)"
        }
        return (module, document)
    }

    func saveProject(_ document: EMathicaDocument) {
        do {
            try projectStore.saveProject(document)
            reloadProjects()
        } catch {
            lastErrorMessage = "保存项目失败：\(error.localizedDescription)"
        }
    }

    func renameProject(id: UUID, title: String) {
        do {
            _ = try projectStore.renameProject(id: id, title: title)
            reloadProjects()
        } catch {
            lastErrorMessage = "重命名失败：\(error.localizedDescription)"
        }
    }

    func previewURL(for projectID: UUID) -> URL? {
        projectStore.previewURL(for: projectID)
    }
}
