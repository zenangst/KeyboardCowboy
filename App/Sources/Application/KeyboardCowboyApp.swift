import SwiftUI
import ViewKit

@main
struct KeyboardCowboyApp: App {
  // swiftlint:disable weak_delegate
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) var scenePhase
  @State var content: MainView?

  var body: some Scene {
    WindowGroup {
      Group {
        if appDelegate.permissionController.hasPrivileges() {
          content
        } else {
          PermissionsView()
        }
      }
      .frame(minWidth: 800, minHeight: 520)
      .onChange(of: scenePhase, perform: { phase in
        if phase == .active {
          content = appDelegate.mainView
        }
      })
      .environmentObject(appDelegate.userSelection)
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
