public extension MachPortSystem.EventTap {
  /// A disabled tap remains disabled until the host decides how to recover.
  enum Disruption: Equatable {
    case timeout
    case userInput
  }
}
