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

    public func derived<DerivedState: Equatable, ExtractedAction>(
        deriveState: @escaping (State) -> DerivedState,
        embedAction: @escaping (ExtractedAction) -> Action
    ) -> Store<DerivedState, ExtractedAction, Environment> {
        let store = Store<DerivedState, ExtractedAction, Environment>(
            initialState: deriveState(state),
            reducer: { _, action, _ in
                self.send(embedAction(action))
                return Empty(completeImmediately: true)
                    .eraseToAnyPublisher()
            },
            environment: environment
        )

        $state
            .map(deriveState)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &store.$state)
        return store
    }

}
