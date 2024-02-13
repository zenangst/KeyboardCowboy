import Cocoa
import SwiftUI

struct ReleaseNotesScene: Scene {
  let appStorage = AppStorageContainer.shared
  @Environment(\.dismiss) var dismiss

  var body: some Scene {
    WindowGroup(id: KeyboardCowboy.releaseNotesWindowIdentifier) {
      Release3_22_0 { action in
        switch action {
        case .done:
          break
        case .wiki:
          NSWorkspace.shared.open(
            URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#macros")!,
            configuration: NSWorkspace.OpenConfiguration()
          )
        }
        NSApplication.shared.keyWindow?.close()
      }
      .onDisappear {
        
      }
    }
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified(showsTitle: true))
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.center)
  }
}
