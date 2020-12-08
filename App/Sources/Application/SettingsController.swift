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
      .sink(receiveValue: { newValue in
        if newValue {
          NSApp.setActivationPolicy(.accessory)
        } else {
          NSApp.setActivationPolicy(.regular)
        }
      }).store(in: &subscriptions)

    userDefaults.publisher(for: \.hideMenuBarIcon) .sink(receiveValue: { newValue in
      self.hideMenuBarIcon.send(newValue)
    }).store(in: &subscriptions)
  }
}
