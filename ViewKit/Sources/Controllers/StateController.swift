import Combine
import SwiftUI

public protocol StateController: ObservableObject where ObjectWillChangePublisher.Output == Void {
  associatedtype State

  var state: State { get }
}

public extension StateController {
  func erase() -> AnyStateController<State> {
    AnyStateController(self)
  }
}

@dynamicMemberLookup
public class AnyStateController<State>: StateController {
  public var objectWillChange: AnyPublisher<Void, Never> { _objectWillChange() }
  public var state: State { _state() }

  private let _objectWillChange: () -> AnyPublisher<Void, Never>
  private let _state: () -> State

  // MARK: - Init

  public init<VC: StateController>(_ stateController: VC) where VC.State == State {
    _objectWillChange = { stateController.objectWillChange.eraseToAnyPublisher() }
    _state = { stateController.state }
  }

  subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
    state[keyPath: keyPath]
  }
}

// MARK: - Extensions

extension AnyStateController: Identifiable where State: Identifiable {
  public var id: State.ID {
    state.id
  }
}
