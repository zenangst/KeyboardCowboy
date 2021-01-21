import Cocoa
import Combine
import Foundation

class SettingsController {
  private let userDefaults: UserDefaults
  private var subscriptions = Set<AnyCancellable>()

  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults

    userDefaults.publisher(for: \.hideDockIcon)
      .sink { newValue in
        if launchArguments.isEnabled(.openWindowAtLaunch) {
          //NSApp.setActivationPolicy(.regular)
          return
        }

        if newValue {
          // NSApp.setActivationPolicy(.accessory)
        } else {
          // NSApp.setActivationPolicy(.regular)
        }
      }.store(in: &subscriptions)
  }
}
