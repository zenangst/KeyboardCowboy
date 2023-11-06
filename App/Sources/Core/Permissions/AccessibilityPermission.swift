import Cocoa
import Combine
import Foundation

@MainActor
final class AccessibilityPermission: ObservableObject {
  enum Permission {
    case authorized
    case pending
    case notDetermined
    case denied
  }

  static let shared = AccessibilityPermission()

  private var timer: AnyCancellable?
  private var runningApplicationSubscription: AnyCancellable?
  @Published private(set) var viewModel: PermissionsItemStatus = .request
  @Published private(set) var permission: Permission = .notDetermined

  init() {
    permission = checkPermission()
    switch permission {
    case .authorized:
      viewModel = .approved
    case .pending:
      viewModel = .pending
    case .notDetermined:
      viewModel = .unknown
    case .denied:
      viewModel = .unknown
    }
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
    let startDate = Date()

    permission = .pending
    viewModel = .pending
    timer = Timer.publish(every: 1, on: .main, in: .default)
      .autoconnect()
      .sink { [weak self] time in
        guard let self else { return }
        let newState = self.checkPermission()
        switch newState {
        case .authorized:
          permission = .authorized
          viewModel = .approved
          NSApplication.shared.setActivationPolicy(.regular)
          NSApplication.shared.activate(ignoringOtherApps: true)
          timer = nil
        default:
          let timeout = (time.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate)
          if timeout > 60 {
            permission = .denied
            viewModel = .unknown
            timer = nil
          }
        }
      }
  }

  @discardableResult
  func checkPermission() -> Permission {
    let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let privOptions = [trusted: false] as CFDictionary
    let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)

    if accessEnabled {
      return .authorized
    } else {
      return .denied
    }
  }
}
