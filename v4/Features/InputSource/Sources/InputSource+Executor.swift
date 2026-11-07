import InputSourceSystem

/// Operations are synchronous and confined to the main actor, like Carbon's controller.
@MainActor
public protocol InputSourceControlling {
  associatedtype Source
  func currentInputSource() throws -> Source
  func id(of source: Source) -> String
  func findInput(_ id: String, includeAllInstalled: Bool) throws -> Source
  func select(_ source: Source) throws
}

extension InputSourceController: InputSourceControlling {
  public func id(of source: InputSourceSystem.InputSource) -> String { source.id }
}

@MainActor
public struct InputSourceExecutor<Controller: InputSourceControlling> {
  private let controller: Controller

  public init(controller: Controller) { self.controller = controller }

  public func run(_ request: InputSourceRequest) async throws {
    let current = try controller.currentInputSource()
    // The legacy runner treats an already-selected source as success even if cancelled.
    if controller.id(of: current) == request.inputSourceId { return }
    try Task.checkCancellation()
    let source = try controller.findInput(request.inputSourceId, includeAllInstalled: false)
    try controller.select(source)
  }
}

public extension InputSourceExecutor where Controller == InputSourceController {
  init() { self.init(controller: InputSourceController()) }
}
