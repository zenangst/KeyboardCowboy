import Commands

public extension WorkflowRuntime {
  struct Step<Payload: Sendable>: Sendable {
    public let metadata: Command.Metadata
    public let payload: Payload

    public init(metadata: Command.Metadata, payload: Payload) {
      self.metadata = metadata
      self.payload = payload
    }
  }
}
