import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneObjectNamingServiceTests {
    private func makeDocument(objects: [MathObject]) -> EMathicaDocument {
        let now = Date()
        return EMathicaDocument(
            metadata: ProjectMetadata(
                title: "NamingTest",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: objects
        )
    }

    private func makeFunction(name: String) -> MathObject {
        MathObject(
            name: name,
            type: .function,
            expression: MathExpression(displayText: name),
            style: MathStyle(colorToken: "blue")
        )
    }

    private func explicitFunctionRelation(_ latex: String) -> AlgebraRelation? {
        AlgebraCore.analyzePlaneLatex(latex).relation
    }

    private func makePoint(name: String) -> MathObject {
        MathObject(
            name: name,
            type: .point,
            expression: MathExpression(displayText: name),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
    }

    @Test func nextFunctionNameUsesSmallestMissingIndex() {
        let service = PlaneObjectNamingService()
        let objects = [
            makeFunction(name: "f_1"),
            makeFunction(name: "f_2"),
            makeFunction(name: "f_4")
        ]

        #expect(service.nextFunctionName(existingObjects: objects) == "f_3")
    }

    @Test func nextPointNameWrapsAfterZ() {
        let service = PlaneObjectNamingService()
        let objects = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { makePoint(name: String($0)) }

        #expect(service.nextPointName(existingObjects: objects) == "A_1")
    }

    @Test func geometryNamesStayIndependent() {
        let service = PlaneObjectNamingService()
        let objects = [
            MathObject(name: "s_1", type: .segment, expression: MathExpression(displayText: "s_1"), style: MathStyle(colorToken: "green")),
            MathObject(name: "ℓ1", type: .line, expression: MathExpression(displayText: "ℓ1"), style: MathStyle(colorToken: "green")),
            MathObject(name: "r1", type: .ray, expression: MathExpression(displayText: "r1"), style: MathStyle(colorToken: "green")),
            MathObject(name: "c1", type: .circle, expression: MathExpression(displayText: "c1"), style: MathStyle(colorToken: "green")),
            MathObject(name: "a1", type: .arc, expression: MathExpression(displayText: "a1"), style: MathStyle(colorToken: "green"))
        ]

        #expect(service.nextSegmentName(existingObjects: objects) == "s_2")
        #expect(service.nextLineName(existingObjects: objects) == "ℓ2")
        #expect(service.nextRayName(existingObjects: objects) == "r2")
        #expect(service.nextCircleName(existingObjects: objects) == "c2")
        #expect(service.nextArcName(existingObjects: objects) == "a2")
    }

    @MainActor
    @Test func planeCommandHandlerSubmitInputUsesSharedAutomaticFunctionNaming() throws {
        let handler = PlaneCommandHandler()
        let existing = [
            makeFunction(name: "f_1"),
            makeFunction(name: "f_2"),
            makeFunction(name: "f_4")
        ]
        let document = makeDocument(objects: existing)

        let output = handler.handle(
            .submitInput,
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "y=x^2")
        )

        let created = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .function {
                return object
            }
            return nil
        }

        #expect(created.count == 1)
        #expect(created.first?.name == "f_3")
    }

    @MainActor
    @Test func workspaceStateCommitFormulaEditingUsesSharedAutomaticFunctionNaming() throws {
        let state = WorkspaceState(
            module: .plane,
            document: makeDocument(objects: [
                makeFunction(name: "f_1"),
                makeFunction(name: "f_2"),
                makeFunction(name: "f_4")
            ]),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        // Force a fresh create session instead of editing the preselected first object.
        state.selectedObjectIDs.removeAll()
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("y=x^2"))
        state.dispatch(.submitInput)

        let created = state.document.objects.filter { $0.type == .function }
        #expect(created.contains(where: { $0.name == "f_3" }))
    }

    @Test func explicitFunctionDefinitionNameIsPreferred() throws {
        let handler = PlaneCommandHandler()
        let document = makeDocument(objects: [])

        let output = handler.handle(
            .createFunction(expression: "g(x)=x^2"),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let created = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .function {
                return object
            }
            return nil
        }

        #expect(created.first?.name == "g")
    }

    @Test func explicitFunctionNameIsKeptWhenUnused() throws {
        let service = PlaneObjectNamingService()
        let objects = [makeFunction(name: "f_1")]

        let resolved = service.resolvedExplicitFunctionName(
            from: explicitFunctionRelation("g(x)=x^2"),
            existingObjects: objects
        )

        #expect(resolved == "g")
    }

    @Test func explicitFunctionNameCollisionUsesSmallestMissingSuffix() throws {
        let service = PlaneObjectNamingService()
        let objects = [
            makeFunction(name: "g"),
            makeFunction(name: "g_1")
        ]

        let resolved = service.resolvedExplicitFunctionName(
            from: explicitFunctionRelation("g(x)=x^2"),
            existingObjects: objects
        )

        #expect(resolved == "g_2")
    }

    @Test func explicitFunctionNameEditingSelfKeepsOriginalName() throws {
        let service = PlaneObjectNamingService()
        let current = makeFunction(name: "g")
        let objects = [
            current,
            makeFunction(name: "h")
        ]

        let resolved = service.resolvedExplicitFunctionName(
            from: explicitFunctionRelation("g(x)=x^2"),
            existingObjects: objects,
            excluding: current.id
        )

        #expect(resolved == "g")
    }

    @Test func explicitFunctionNameEditingSelfResolvesOtherConflict() throws {
        let service = PlaneObjectNamingService()
        let current = makeFunction(name: "g")
        let objects = [
            current,
            makeFunction(name: "h")
        ]

        let resolved = service.resolvedExplicitFunctionName(
            from: explicitFunctionRelation("h(x)=x^2"),
            existingObjects: objects,
            excluding: current.id
        )

        #expect(resolved == "h_1")
    }

    @MainActor
    @Test func planeCommandHandlerCreateFunctionUsesExplicitCollisionResolution() throws {
        let handler = PlaneCommandHandler()
        let document = makeDocument(objects: [
            makeFunction(name: "g")
        ])

        let output = handler.handle(
            .createFunction(expression: "g(x)=x^2"),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let created = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .function {
                return object
            }
            return nil
        }

        #expect(created.first?.name == "g_1")
    }

    @MainActor
    @Test func workspaceStateCommitFormulaEditingUsesExplicitCollisionResolution() throws {
        let state = WorkspaceState(
            module: .plane,
            document: makeDocument(objects: [
                makeFunction(name: "g")
            ]),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        // Force a fresh create session instead of editing the preselected first object.
        state.selectedObjectIDs.removeAll()
        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("g(x)=x^2"))
        state.dispatch(.submitInput)

        let created = state.document.objects.filter { $0.type == .function }
        #expect(created.contains(where: { $0.name == "g_1" }))
    }

    @MainActor
    @Test func workspaceStateEditingSelfKeepsExplicitName() throws {
        let state = WorkspaceState(
            module: .plane,
            document: makeDocument(objects: [
                makeFunction(name: "g"),
                makeFunction(name: "h")
            ]),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("g(x)=x^2"))
        state.dispatch(.submitInput)

        #expect(state.document.objects.contains(where: { $0.type == .function && $0.name == "g" }))
    }

    @MainActor
    @Test func workspaceStateEditingCollisionRenamesToSmallestMissingSuffix() throws {
        let state = WorkspaceState(
            module: .plane,
            document: makeDocument(objects: [
                makeFunction(name: "g"),
                makeFunction(name: "h")
            ]),
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.openInput(mode: .expression))
        state.dispatch(.updateInputText("h(x)=x^2"))
        state.dispatch(.submitInput)

        #expect(state.document.objects.contains(where: { $0.type == .function && $0.name == "h_1" }))
    }
}
