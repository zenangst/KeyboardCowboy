public extension KeyCodeSystem {
  enum LookupError: Error, Equatable {
    case layoutUnavailable
    case inputSourceUnavailable(String)
  }
}
