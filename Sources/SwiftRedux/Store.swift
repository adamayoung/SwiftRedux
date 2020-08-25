import Combine
import Foundation

public final class Store<State: Equatable, Action, Environment>: ObservableObject {

    @Published private(set) public var state: State

    private let environment: Environment
    private let reducer: Reducer<State, Action, Environment>
    private var cancellables: Set<AnyCancellable> = []
    private var derivedCancellable: AnyCancellable?

    public init(
        initialState: State,
        reducer: @escaping Reducer<State, Action, Environment>,
        environment: Environment
    ) {
        self.state = initialState
        self.reducer = reducer
        self.environment = environment
    }

    public func send(_ action: Action) {
        guard let effect = reducer(&state, action, environment) else {
            return
        }

        effect
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &cancellables)
    }

    public func derived<DerivedState: Equatable, DerivedAction>(
        deriveState: @escaping (State) -> DerivedState,
        deriveAction: @escaping (DerivedAction) -> Action
    ) -> Store<DerivedState, DerivedAction, Environment> {
        let store = Store<DerivedState, DerivedAction, Environment>(
            initialState: deriveState(state),
            reducer: { _, action, _ in
                self.send(deriveAction(action))
                return Empty(completeImmediately: true)
                    .eraseToAnyPublisher()
            },
            environment: environment
        )

        store.derivedCancellable = $state
            .map(deriveState)
            .removeDuplicates()
            .sink { [weak store] in store?.state = $0 }

        return store
    }

}
