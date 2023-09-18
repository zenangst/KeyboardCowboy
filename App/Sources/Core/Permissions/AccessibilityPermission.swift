import Cocoa
import Combine
import Foundation

final class AccessibilityPermission: ObservableObject {
  enum Permission {
    case authorized
    case pending
    case notDetermined
    case denied
  }

  static let shared = AccessibilityPermission()

  private var runningApplicationSubscription: AnyCancellable?
  @Published private(set) var viewModel: PermissionsItemStatus = .request
  @Published private(set) var permission: Permission = .notDetermined

  init() {
    permission = checkPermission()
  }

  func subscribe(to publisher: Published<RunningApplication?>.Publisher, onAuthorized: @escaping () -> Void) {
    runningApplicationSubscription = publisher.sink { [weak self] _ in
      guard let self else { return }
      permission = checkPermission()
      if permission == .authorized {
        runningApplicationSubscription = nil
        onAuthorized()
      }
    }
  }

  func requestPermission() {
    let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let privOptions = [trusted: true] as CFDictionary
    let _ = AXIsProcessTrustedWithOptions(privOptions)
    permission = .pending
    viewModel = .pending
  }

  func checkPermission() -> Permission {
    let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let privOptions = [trusted: false] as CFDictionary
    let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)

    if accessEnabled {
      viewModel = .approved
      return .authorized
    } else {
      viewModel = .request
      return .denied
    }
  }
}
