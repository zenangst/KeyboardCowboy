import SwiftUI

struct PermissionsScene: Scene {
  var onAction: (PermissionsView.Action) -> Void

  var body: some Scene {
    WindowGroup(id: KeyboardCowboy.permissionsWindowIdentifier) {
      PermissionsView(onAction: onAction)
        .toolbar(content: {
          Spacer()
          Text("Keyboard Cowboy: Permissions")
          Spacer()
        })
        .frame(width: 640, height: 560)
    }
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified(showsTitle: true))
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.center)
  }
}
