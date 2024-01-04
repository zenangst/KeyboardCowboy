import SwiftUI

struct PermissionsWindow: Scene {
  var body: some Scene {
    WindowGroup(id: KeyboardCowboy.permissionsSettingsWindowIdentifier) {
      PermissionsSettings()
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)
  }
}
