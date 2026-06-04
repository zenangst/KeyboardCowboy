import SwiftUI

@main
struct V4App: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup("v4") {
      MainContentView()
        .frame(minWidth: 480, minHeight: 320)
    }
    .commands {
      CommandGroup(replacing: .appInfo) {
        Button("About Keyboard Cowboy") {
          NSApp.orderFrontStandardAboutPanel(nil)
          NSApp.activate(ignoringOtherApps: true)
        }
      }
    }
  }
}

