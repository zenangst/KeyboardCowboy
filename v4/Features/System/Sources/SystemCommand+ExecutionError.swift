public extension SystemCommand {
  enum ExecutionError: Error, Equatable {
    case dockUnavailable
    case missingPreviousApplicationBundleURL(String)
  }
}
