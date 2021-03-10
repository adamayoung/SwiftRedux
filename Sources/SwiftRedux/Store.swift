import Combine
import Foundation
import SwiftUI

public final class Store<State, Action>: ObservableObject {

    @Published private(set) public var state: State

    private let reduce: (inout State, Action) -> AnyPublisher<Action, Never>
    private var effectCancellables: [UUID: AnyCancellable] = [:]
    private let queue: DispatchQueue

    public init<Environment>(
        initialState: State,
        reducer: Reducer<State, Action, Environment>,
        environment: Environment,
        subscriptionQueue: DispatchQueue = .init(label: "com.aaplab.store")
    ) {
        self.queue = subscriptionQueue
        self.state = initialState
        self.reduce = { state, action in
            reducer(&state, action, environment)
        }
    }

    public func send(_ action: Action) {
        let effect = reduce(&state, action)

        var didComplete = false
        let uuid = UUID()

        let cancellable = effect
            .subscribe(on: queue)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    didComplete = true
                    self?.effectCancellables[uuid] = nil
                },
                receiveValue: { [weak self] in self?.send($0) }
            )

        if !didComplete {
            effectCancellables[uuid] = cancellable
        }
    }

    public func derived<DerivedState: Equatable, ExtractedAction>(
        deriveState: @escaping (State) -> DerivedState,
        embedAction: @escaping (ExtractedAction) -> Action
    ) -> Store<DerivedState, ExtractedAction> {
        let store = Store<DerivedState, ExtractedAction>(
            initialState: deriveState(state),
            reducer: Reducer { _, action, _ in
                self.send(embedAction(action))
                return Empty().eraseToAnyPublisher()
            },
            environment: ()
        )

        $state
            .subscribe(on: store.queue)
            .map(deriveState)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &store.$state)

        return store
    }

    public func binding<Value>(
            for keyPath: KeyPath<State, Value>,
            toAction: @escaping (Value) -> Action
        ) -> Binding<Value> {
            Binding<Value>(
                get: { self.state[keyPath: keyPath] },
                set: { self.send(toAction($0)) }
            )
        }

}

extension Store {

    public static func stub(with state: State) -> Store {
        Store(
            initialState: state,
            reducer: Reducer { _, _, _ in Empty<Action, Never>().eraseToAnyPublisher() },
            environment: ()
        )
    }

}
