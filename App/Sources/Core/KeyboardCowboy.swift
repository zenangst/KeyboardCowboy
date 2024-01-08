import ApplicationServices
import AXEssibility
import Bonzai
import Combine
import Cocoa
import SwiftUI
import LaunchArguments
import InputSources
@_exported import Inject

@main
struct KeyboardCowboy: App {
#if DEBUG
  static func env() -> AppEnvironment {
    guard !isRunningPreview else { return .previews }

    if let override = ProcessInfo.processInfo.environment["APP_ENVIRONMENT_OVERRIDE"],
       let env = AppEnvironment(rawValue: override) {
      return env
    } else {
      return .production
    }
  }
#else
  static func env() -> AppEnvironment { .production }
#endif

  @FocusState var focus: AppFocus?
  @Namespace var namespace
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private var open: Bool = true
  private let core: Core
  @ObservedObject private var contentStore: ContentStore
  @Environment(\.openWindow) private var openWindow

  init() {
    let core = Core()
    contentStore = core.contentStore
    self.core = core

    Task {
      await MainActor.run {
        Inject.animation = .spring()
        Benchmark.shared.isEnabled = launchArguments.isEnabled(.benchmark)
      }
    }

    if launchArguments.isEnabled(.injection) { _ = Inject.load }
  }

  var body: some Scene {
    AppMenuBarExtras(onAction: handleAppExtraAction(_:))
    MainWindow(core, onScene: handleAppScene(_:))

    Settings(content: { 
      SettingsView().environmentObject(OpenPanelController())
    })
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)

    PermissionsWindow()
    PermissionsScene(onAction: handlePermissionAction(_:))

    NewCommandWindow(contentStore: core.contentStore, 
                     uiElementCaptureStore: core.uiElementCaptureStore,
                     configurationPublisher: core.configCoordinator.configurationPublisher) { workflowId, commandId, title, payload in
      let groupIds = core.groupSelectionManager.selections
      Task {
        await core.detailCoordinator.addOrUpdateCommand(payload, workflowId: workflowId,
                                                               title: title, commandId: commandId)
        core.contentCoordinator.handle(.selectWorkflow(workflowIds: [workflowId], groupIds: groupIds))
        core.contentCoordinator.handle(.refresh(groupIds))
      }
    }

    EditWorkflowGroupWindow(core.contentStore, configurationPublisher: core.configCoordinator.configurationPublisher) { context in
      core.sidebarCoordinator.handle(context)
      core.contentCoordinator.handle(context)
    }
  }

  private func handleAppExtraAction(_ action: AppMenuBarExtras.Action) {
    guard !launchArguments.isEnabled(.runningUnitTests) else { return }
    switch action {
    case .onAppear:
      if KeyboardCowboy.env() == .development {
        handleAppScene(.mainWindow)
      } else {
        if !AXIsProcessTrustedWithOptions(nil) {
          handleAppScene(.permissions)
          return
        }
      }
    case .openMainWindow:
      handleAppScene(.mainWindow)
    case .reveal:
      NSWorkspace.shared.selectFile(Bundle.main.bundlePath, inFileViewerRootedAtPath: "")
    }
  }

  private func handleAppScene(_ scene: AppScene) {
    guard KeyboardCowboy.env() != .previews else { return }
    switch scene {
    case .permissions:
      openWindow(id: KeyboardCowboy.permissionsWindowIdentifier)
      KeyboardCowboy.activate()
    case .mainWindow:
      if let mainWindow = KeyboardCowboy.mainWindow {
        mainWindow.makeKeyAndOrderFront(nil)
      } else {
        openWindow(id: KeyboardCowboy.mainWindowIdentifier)
      }
    case .addGroup:
      openWindow(value: EditWorkflowGroupWindow.Context.add(WorkflowGroup.empty()))
    case .editGroup(let groupId):
      if let workflowGroup = core.groupStore.group(withId: groupId) {
        openWindow(value: EditWorkflowGroupWindow.Context.edit(workflowGroup))
      } else {
        assertionFailure("Unable to find workflow group")
      }
    }
  }

  private func handlePermissionAction(_ action: PermissionsView.Action) {
    switch action {
    case .github:
      NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy")!)
    case .requestPermissions:
      NSApplication.shared.keyWindow?.close()
      openWindow(id: KeyboardCowboy.permissionsSettingsWindowIdentifier)
      AccessibilityPermission.shared.requestPermission()
    }
  }

}
