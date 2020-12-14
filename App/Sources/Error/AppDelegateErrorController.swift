import Cocoa

final class AppDelegateErrorController {
  /// Display an error using `NSAlert`
  /// - Parameter error: The error that should be displayed
  static func handle(_ error: Error) {
    let alert = NSAlert()
    alert.messageText = error.localizedDescription
    if case .dataCorrupted(let context) = error as? DecodingError {
      alert.informativeText = context.underlyingError?.localizedDescription ?? ""
      alert.messageText = context.debugDescription
    }
    alert.runModal()
  }
}
