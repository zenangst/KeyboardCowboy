import Cocoa
import Combine
import Foundation

final class AppPermissions {
  var runningApplicationSubscription: AnyCancellable?
  @Published var hasPermissions: Bool = false

  func subscribe(to publisher: Published<RunningApplication?>.Publisher) {
    runningApplicationSubscription = publisher.sink { [weak self] _ in
      guard let self else { return }
      let value = hasPrivileges(shouldPrompt: false)
      if value {
        runningApplicationSubscription = nil
        hasPermissions = true
      }
    }
  }

  func hasPrivileges(shouldPrompt: Bool) -> Bool {
    let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let privOptions = [trusted: shouldPrompt] as CFDictionary
    let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)
    return accessEnabled
  }
}
