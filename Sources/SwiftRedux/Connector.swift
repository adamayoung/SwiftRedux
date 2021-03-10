import Foundation

public protocol Connector {

    associatedtype State
    associatedtype Action
    associatedtype ViewState: Equatable
    associatedtype ViewAction: Equatable

    func connect(state: State) -> ViewState
    func connect(action: ViewAction) -> Action

}

public extension Store {

    func connect<C: Connector>(
        using connector: C
    ) -> Store<C.ViewState, C.ViewAction> where C.State == State, C.Action == Action {
        derived(
            deriveState: connector.connect(state: ),
            embedAction: connector.connect(action: )
        )
    }

}
