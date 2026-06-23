import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct PlaneInputDockPolishTests {
    @Test func inputSessionStatusLabelReflectsCreateAndEditModes() throws {
        let createState = makeWorkspaceState(objects: [])
        createState.dispatch(.openInput(mode: .expression))
        #expect(createState.inputSessionStatusLabel == "新建函数")
        #expect(createState.inputSessionModeBadgeText == "新建")
        #expect(createState.inputSessionPrimaryTitle == "输入函数或表达式")
        #expect(createState.inputSessionSecondaryTitle == "支持函数、参数曲线、极坐标等二维表达式入口")

        let object = MathObject(
            name: "f_1",
            type: .function,
            expression: MathExpression(
                displayText: "x^2",
                sourceExpression: "x^2",
                computeExpression: "x^2"
            ),
            style: MathStyle(colorToken: "blue")
        )
        let editState = makeWorkspaceState(objects: [object])
        editState.beginEditingObjectExpression(object.id, openKeyboard: false)
        #expect(editState.inputSessionStatusLabel == "编辑 f_1")
        #expect(editState.inputSessionModeBadgeText == "编辑")
        #expect(editState.inputSessionPrimaryTitle == "编辑 f_1")
        #expect(editState.inputSessionSecondaryTitle == "修改当前对象的数学定义，提交后会直接更新画布")
    }

    @Test func closedInputStillExposesClearExpressionEntryPrompt() throws {
        let state = makeWorkspaceState(objects: [])

        #expect(state.inputSessionStatusLabel == nil)
        #expect(state.inputSessionModeBadgeText == nil)
        #expect(state.inputSessionPrimaryTitle == "输入函数或表达式")
        #expect(state.inputSessionSecondaryTitle == "轻点这里输入函数、参数曲线或极坐标表达式")
    }

    @Test func commitErrorMessageClearsOnInputChangeCancelAndSuccess() throws {
        let state = makeWorkspaceState(objects: [])

        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("sin("))
        state.dispatch(.submitInput)
        #expect(state.commitErrorMessage != nil)

        state.dispatch(.updateInputText("sin(x)"))
        #expect(state.commitErrorMessage == nil)

        state.dispatch(.updateInputText("sin("))
        state.dispatch(.submitInput)
        #expect(state.commitErrorMessage != nil)

        state.cancelFormulaEditing()
        #expect(state.commitErrorMessage == nil)

        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("x^2"))
        state.dispatch(.submitInput)
        #expect(state.commitErrorMessage == nil)
    }

    private func makeWorkspaceState(objects: [MathObject]) -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "Input Dock Polish Test",
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
