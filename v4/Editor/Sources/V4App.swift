import SwiftUI

@main
struct V4App: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var dependencies = RootDependencies()

  var body: some Scene {
    WindowGroup("v4") {
      MainContentView()
        .frame(minWidth: 480, minHeight: 320)
        .environment(\.brand, dependencies.brand)
        .environment(\.cornerRadiusValue, dependencies.brand.cornerRadius.large)
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
