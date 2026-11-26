public extension ProcessSystem.Process {
  enum CaptureError: Swift.Error, Equatable {
    case standardOutputLimitExceeded(limit: Int)
    case standardErrorLimitExceeded(limit: Int)
  }
}
