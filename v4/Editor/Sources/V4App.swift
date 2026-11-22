import SwiftUI

@main
struct V4App: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var dependencies = RootDependencies()

  var body: some Scene {
    WindowGroup("v4") {
      content
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

  @ViewBuilder
  private var content: some View {
    #if DEBUG
    if let preview = CapturePreview(arguments: Array(CommandLine.arguments.dropFirst())) {
      preview
    } else {
      editor
    }
    #else
    editor
    #endif
  }

  private var editor: some View {
    MainContentView()
      .frame(minWidth: 480, minHeight: 320)
      .environment(\.brand, dependencies.brand)
      .environment(\.cornerRadiusValue, dependencies.brand.cornerRadius.large)
  }
}
