import Cocoa
import LogicFramework

final class ErrorController {
  static private let factory = ControllerFactory.shared

  /// Display an error using `NSAlert`
  /// - Parameter error: The error that should be displayed
  static func handle(_ error: Error) {
    let permissionController = factory.permissionsController()
    if !permissionController.hasPrivileges() {
      permissionController.displayModal()
      return
    }
    displayModal(for: error)
  }

  static func displayModal(for error: Error) {
    let alert = NSAlert()
    alert.messageText = error.localizedDescription
    if case .dataCorrupted(let context) = error as? DecodingError {
      alert.informativeText = context.underlyingError?.localizedDescription ?? ""
      alert.messageText = context.debugDescription
    }
    alert.runModal()
  }
}
