import SwiftUI
import ViewKit

@main
struct KeyboardCowboyApp: App {
  // swiftlint:disable weak_delegate
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) var scenePhase
  @State var content: AnyView?

  let applicationName: String = "Keyboard Cowboy"

  var body: some Scene {
    WindowGroup {
      ZStack {
        if appDelegate.permissionController.hasPrivileges() {
          content.frame(minWidth: 800, minHeight: 520)
        } else {
          ZStack {
            Color(.windowBackgroundColor)
            VStack {
              Image("ApplicationIcon")
                .resizable()
                .frame(width: 256, height: 256)
              Text(appDelegate.permissionController.informativeText)
            }
          }.frame(minWidth: 800, minHeight: 520)
        }
      }.frame(minWidth: 800, minHeight: 520)
      .onChange(of: scenePhase, perform: { _ in
        content = appDelegate.mainView?.environmentObject(appDelegate.userData).erase()
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
