import Cocoa
import Combine
import Foundation

class SettingsController {
  var hideMenuBarIcon = PassthroughSubject<Bool, Never>()
  private let userDefaults: UserDefaults
  private var subscriptions = Set<AnyCancellable>()

  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults

    userDefaults.publisher(for: \.hideDockIcon)
      .sink { newValue in
        if launchArguments.isEnabled(.openWindowAtLaunch) {
          NSApp.setActivationPolicy(.regular)
          return
        }

        if newValue {
          NSApp.setActivationPolicy(.accessory)
        } else {
          NSApp.setActivationPolicy(.regular)
        }
      }.store(in: &subscriptions)

    userDefaults.publisher(for: \.hideMenuBarIcon).sink {
      self.hideMenuBarIcon.send($0)
    }.store(in: &subscriptions)
  }
}
