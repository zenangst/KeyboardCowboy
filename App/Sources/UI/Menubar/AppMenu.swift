import Bonzai
import SwiftUI

struct AppMenu: View {
  @StateObject var appUpdater = AppUpdater()
  @StateObject var loginItem = LoginItem()
  @ObservedObject var modePublisher: KeyboardCowboyModePublisher

  private let onEnableToggle: (Bool) -> Void

  init(modePublisher: KeyboardCowboyModePublisher, onEnableToggle: @escaping (Bool) -> Void) {
    self.modePublisher = modePublisher
    self.onEnableToggle = onEnableToggle
  }

  var body: some View {
    Button { appUpdater.checkForUpdates() } label: { Text("Check for updates…") }
    Toggle(isOn: $loginItem.isEnabled, label: { Text("Open at Login") })
      .toggleStyle(.checkbox)

    Toggle(isOn: Binding<Bool>.init(get: { modePublisher.isEnabled },
                                    set: { newValue in onEnableToggle(newValue) }))
    { Text("Enabled") }
  }
}

