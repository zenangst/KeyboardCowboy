import SwiftUI

@main
struct KeyboardCowboyApp: App {
  // swiftlint:disable weak_delegate
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) var scenePhase
  @State var content: AnyView?

  var body: some Scene {
    WindowGroup {
      VStack {
        content
      }
      .frame(minWidth: 800, minHeight: 520)
      .onChange(of: scenePhase, perform: { _ in
        content = appDelegate.mainView?.environmentObject(appDelegate.userSelection).erase()
      })
    }
    .windowToolbarStyle(UnifiedWindowToolbarStyle())
    .commands {
      CommandGroup(after: CommandGroupPlacement.toolbar, addition: {
        Button("Toggle Sidebar") {
          NSApp.keyWindow?.firstResponder?.tryToPerform(
            #selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        }.keyboardShortcut("S")
      })
    }
  }
}
