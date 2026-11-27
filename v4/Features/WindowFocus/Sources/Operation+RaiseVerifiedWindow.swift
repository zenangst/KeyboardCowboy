import CoreGraphics

extension Operation {
  enum RaiseVerifiedWindow {
    /// The caller keeps these elements inside one accessibility transaction.
    static func run<Window>(
      id: CGWindowID,
      windows: () throws -> [Window],
      identity: (Window) throws -> CGWindowID?,
      isCurrent: () throws -> Bool,
      raise: (Window) throws -> Void,
    ) throws -> Bool {
      guard id != 0 else { return false }
      var target: Window?
      for window in try windows() where try identity(window) == id {
        guard target == nil else { return false }
        target = window
      }
      guard let target, try identity(target) == id, try isCurrent() else { return false }

      try Task.checkCancellation()
      try raise(target)
      return true
    }
  }
}
