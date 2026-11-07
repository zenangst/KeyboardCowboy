import InputSourceSystem

public extension InputSource {
  @MainActor
  struct Executor {
    private let controller: InputSource.Controller

    public init(controller: InputSource.Controller = InputSource.Controller()) {
      self.controller = controller
    }

    public func run(_ request: InputSource.Request) async throws {
      let current = try controller.currentInputSource()
      // The legacy runner treats an already-selected source as success even if cancelled.
      if current.id == request.inputSourceId { return }
      try Task.checkCancellation()
      let source = try controller.findInput(request.inputSourceId, includeAllInstalled: false)
      try controller.select(source)
    }
  }
}
