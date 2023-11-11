protocol ApplicationRoutine {
  
  /// Run a custom application routine
  /// - Returns: `true` if the routine should exit.
  func run() async -> Bool
}
