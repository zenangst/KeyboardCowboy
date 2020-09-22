import Combine
import SwiftUI

public protocol ViewController: ObservableObject where ObjectWillChangePublisher.Output == Void {
  associatedtype State
  associatedtype Action

  var state: State { get }
  func perform(_ action: Action)
}

public extension ViewController {
  func erase() -> AnyViewController<State, Action> {
    AnyViewController(self)
  }
}

// MARK: - AnyViewController

@dynamicMemberLookup
public final class AnyViewController<State, Action>: ViewController {
  public var objectWillChange: AnyPublisher<Void, Never> { _objectWillChange() }
  public var state: State { _state() }

  private let _objectWillChange: () -> AnyPublisher<Void, Never>
  private let _state: () -> State
  private let _perform: (Action) -> Void

  // MARK: - Init

  public init<VC: ViewController>(_ viewController: VC) where VC.State == State, VC.Action == Action {
    _objectWillChange = { viewController.objectWillChange.eraseToAnyPublisher() }
    _state = { viewController.state }
    _perform = viewController.perform
  }

  // MARK: - Public API

  public func perform(_ action: Action) {
    _perform(action)
  }

  // MARK: - Internal API

  func action(_ action: Action) -> () -> Void {
    return { [weak self] in
      self?._perform(action)
    }
  }

  func bind<Value>(
    _ keyPath: KeyPath<State, Value>,
    _ perform: @escaping ((Value) -> Action)
  ) -> Binding<Value> {
    Binding<Value>(
      get: { [unowned self] in self.state[keyPath: keyPath] },
      set: { [weak self] in
        self?.perform(perform($0))
      }
    )
  }

  subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
    state[keyPath: keyPath]
  }
}

// MARK: - Extensions

extension AnyViewController: Identifiable where State: Identifiable {
  public var id: State.ID {
    state.id
  }
}
