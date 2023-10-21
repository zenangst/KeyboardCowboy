import SwiftUI

struct AppMenu: View {
  @StateObject var appUpdater = AppUpdater()
  @StateObject var loginItem = LoginItem()

  var body: some View {
    Button { appUpdater.checkForUpdates() } label: { Text("Check for updates…") }
    Toggle(isOn: $loginItem.isEnabled, label: { Text("Open at Login") })
      .toggleStyle(.checkbox)
  }
}

