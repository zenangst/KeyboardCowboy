import InputSourceSystem

public extension InputSource {
  /// Operations are synchronous and confined to the main actor, like Carbon's controller.
  @MainActor
  protocol Controlling {
    associatedtype Source
    func currentInputSource() throws -> Source
    func id(of source: Source) -> String
    func findInput(_ id: String, includeAllInstalled: Bool) throws -> Source
    func select(_ source: Source) throws
  }

  @MainActor
  struct Executor<Controller: Controlling> {
    private let controller: Controller

    public init(controller: Controller) { self.controller = controller }

    public func run(_ request: InputSource.Request) async throws {
      let current = try controller.currentInputSource()
      // The legacy runner treats an already-selected source as success even if cancelled.
      if controller.id(of: current) == request.inputSourceId { return }
      try Task.checkCancellation()
      let source = try controller.findInput(request.inputSourceId, includeAllInstalled: false)
      try controller.select(source)
    }
  }
}

extension InputSource.Controller: InputSource.Controlling {
  public func id(of source: InputSource) -> String { source.id }
}

public extension InputSource.Executor where Controller == InputSource.Controller {
  init() { self.init(controller: InputSource.Controller()) }
}
