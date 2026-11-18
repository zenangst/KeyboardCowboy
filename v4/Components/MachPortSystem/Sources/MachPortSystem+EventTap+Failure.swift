public extension MachPortSystem.EventTap {
  enum Failure: Swift.Error, Equatable {
    case creationFailed
    case eventSourceCreationFailed
    case unsupportedTapOptions
  }
}
