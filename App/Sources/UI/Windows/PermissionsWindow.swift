import SwiftUI

struct PermissionsWindow: Scene {
  var body: some Scene {
    WindowGroup(id: KeyboardCowboyApp.permissionsSettingsWindowIdentifier) {
      PermissionsSettingsView()
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)
  }
}
