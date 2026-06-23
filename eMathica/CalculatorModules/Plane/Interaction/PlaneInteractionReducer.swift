import Foundation

enum PlaneInteractionReducer {
    static func reduce(state: inout PlaneInteractionState, event: PlaneInteractionEvent) {
        switch event {
        case .reset:
            state = PlaneInteractionState()
        }
    }
}

enum PlaneInteractionEvent: Hashable {
    case reset
}

