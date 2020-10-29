import Foundation

public protocol ActionController {
  associatedtype Action

  func perform(_ action: Action)
}

public extension ActionController {
  func erase() -> AnyActionController<Action> {
    AnyActionController(self)
  }
}

public final class AnyActionController<Action>: ActionController {
  private let _perform: (Action) -> Void

  // MARK: - Init

  public init<VC: ActionController>(_ viewController: VC) where VC.Action == Action {
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
}
