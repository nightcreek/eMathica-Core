import Foundation
import Testing
import SwiftUI
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct PlaneCompactKeyboardPolishTests {
    @Test func compactHeightLayoutHelperUsesAvailableHeightThreshold() {
        let spaciousMetrics = WorkspaceLayoutMetrics.make(
            size: CGSize(width: 1024, height: 900),
            safeInsets: EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0)
        )
        #expect(spaciousMetrics.isCompactKeyboardLayout == false)

        let shortMetrics = WorkspaceLayoutMetrics.make(
            size: CGSize(width: 1024, height: 680),
            safeInsets: EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0)
        )
        #expect(shortMetrics.isCompactKeyboardLayout == true)
    }

    @Test func compactHeightDefaultsToCollapsedKeyboardButAllowsManualExpansion() {
        let state = makeWorkspaceState(objects: [])
        state.updateCompactHeightLayout(true)
        state.dispatch(.openInput(mode: .expression))

        #expect(state.isInputPresented == true)
        #expect(state.isKeyboardPresented == false)

        state.toggleMathKeyboardFromFormulaBar()
        #expect(state.isKeyboardPresented == true)

        state.updateCompactHeightLayout(true)
        #expect(state.isKeyboardPresented == true)

        state.updateCompactHeightLayout(false)
        #expect(state.isKeyboardPresented == true)
    }

    @Test func compactHeightRestoresAutoCollapsedKeyboardWhenLeavingCompact() {
        let state = makeWorkspaceState(objects: [])
        state.dispatch(.openInput(mode: .expression))
        #expect(state.isKeyboardPresented == true)

        state.updateCompactHeightLayout(true)
        #expect(state.isKeyboardPresented == false)

        state.updateCompactHeightLayout(false)
        #expect(state.isKeyboardPresented == true)
    }

    private func makeWorkspaceState(objects: [MathObject]) -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "Compact Keyboard Polish Test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: objects)
        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneWorkspaceModuleProvider().toolGroups,
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }
}
