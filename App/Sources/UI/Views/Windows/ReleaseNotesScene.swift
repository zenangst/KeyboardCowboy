import Cocoa
import SwiftUI

struct ReleaseNotesScene: Scene {
  let appStorage = AppStorageContainer.shared
  @Environment(\.dismiss) var dismiss

  var body: some Scene {
    WindowGroup(id: KeyboardCowboy.releaseNotesWindowIdentifier) {
      Release3_25_0 { action in
        switch action {
        case .done:
          NSApplication.shared.keyWindow?.close()
        }
      }
      .onDisappear {
        AppStorageContainer.shared.releaseNotes = KeyboardCowboy.marketingVersion
      }
    }
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified(showsTitle: true))
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.center)
  }
}
