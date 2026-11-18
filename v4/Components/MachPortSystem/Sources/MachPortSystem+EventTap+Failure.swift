public extension MachPortSystem.EventTap {
  enum Failure: Swift.Error, Equatable {
    case creationFailed
    case enableFailed
    case eventSourceCreationFailed
    case unsupportedTapOptions
  }
}
