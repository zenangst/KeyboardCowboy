import SwiftUI
import ViewKit

@main
struct KeyboardCowboyApp: App {
  // swiftlint:disable weak_delegate
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) var scenePhase
  @State var content: MainView?
  private var firstResponder: NSResponder? { NSApp.keyWindow?.firstResponder }

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
      CommandGroup(replacing: CommandGroupPlacement.pasteboard, addition: {

        Button("Copy") {
          firstResponder?.tryToPerform(#selector(NSText.copy(_:)), with: nil)
        }.keyboardShortcut("c", modifiers: [.command])

        Button("Paste") {
          firstResponder?.tryToPerform(#selector(NSText.paste(_:)), with: nil)
        }.keyboardShortcut("v", modifiers: [.command])

        Button("Delete") {
          firstResponder?.tryToPerform(#selector(NSText.delete(_:)), with: nil)
        }.keyboardShortcut(.delete, modifiers: [])

        Button("Select All") {
          firstResponder?.tryToPerform(#selector(NSText.selectAll(_:)), with: nil)
        }.keyboardShortcut("a", modifiers: [.command])
      })

      CommandGroup(replacing: CommandGroupPlacement.newItem, addition: {
        Button("New Workflow") {
          if let group = appDelegate.userSelection.group {
            appDelegate.workflowFeatureController?.perform(.createWorkflow(in: group))
          }
        }.keyboardShortcut("n", modifiers: [.command])

        Button("New Group") {
          appDelegate.groupFeatureController?.perform(.createGroup)
        }.keyboardShortcut("N", modifiers: [.command, .shift])
      })

      CommandGroup(after: CommandGroupPlacement.toolbar, addition: {
        Button("Toggle Sidebar") {
          firstResponder?.tryToPerform(
            #selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        }.keyboardShortcut("S")
      })
    }

    Settings {
      SettingsView()
    }
  }
}
