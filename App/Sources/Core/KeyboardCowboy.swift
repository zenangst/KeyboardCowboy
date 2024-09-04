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
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private var open: Bool = true
  private let core: Core
  @ObservedObject private var contentStore: ContentStore
  @Environment(\.openWindow) private var openWindow

  init() {
    let core = Core()
    contentStore = core.contentStore
    self.core = core
    self.appDelegate.core = core

    Task { @MainActor in
      InjectConfiguration.animation = .spring()
      Benchmark.shared.isEnabled = launchArguments.isEnabled(.benchmark)
    }

    if launchArguments.isEnabled(.injection) { _ = InjectConfiguration.load }
  }

  var body: some Scene {
    AppMenuBarExtras(contentStore: core.contentStore, onAction: handleAppExtraAction(_:))
    MainWindow(core, onScene: handleAppScene(_:))

    Settings(content: { 
      SettingsView().environmentObject(OpenPanelController())
    })
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)

    EmptyConfigurationWindow(onAction: core.contentStore.handle(_:))
    PermissionsWindow()
    PermissionsScene(onAction: handlePermissionAction(_:))
    ReleaseNotesScene()

    NewCommandWindow(contentStore: core.contentStore, 
                     uiElementCaptureStore: core.uiElementCaptureStore,
                     configurationPublisher: core.configCoordinator.configurationPublisher) { workflowId, commandId, title, payload in
      let groupIds = core.groupSelectionManager.selections
      Task {
        await core.detailCoordinator.addOrUpdateCommand(payload, workflowId: workflowId,
                                                        title: title, commandId: commandId)
        core.contentCoordinator.handle(.selectWorkflow(workflowIds: [workflowId]))
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

        if AppStorageContainer.shared.releaseNotes < KeyboardCowboy.marketingVersion {
          openWindow(id: KeyboardCowboy.releaseNotesWindowIdentifier)
        }
      }
    case .openEmptyConfigurationWindow:
      openWindow(id: KeyboardCowboy.emptyConfigurationWindowIdentifier)
    case .openMainWindow:
      handleAppScene(.mainWindow)
    case .reveal:
      NSWorkspace.shared.selectFile(Bundle.main.bundlePath, inFileViewerRootedAtPath: "")
      NSWorkspace.shared.runningApplications
        .first(where: { $0.bundleIdentifier?.lowercased().contains("apple.finder") == true })?
        .activate()
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
      KeyboardCowboy.activate()
    case .addGroup:
      openWindow(value: EditWorkflowGroupWindow.Context.add(WorkflowGroup.empty()))
    case .editGroup(let groupId):
      if let workflowGroup = core.groupStore.group(withId: groupId) {
        openWindow(value: EditWorkflowGroupWindow.Context.edit(workflowGroup))
      } else {
        assertionFailure("Unable to find workflow group")
      }
    case .addCommand(let workflowId):
      openWindow(value: NewCommandWindow.Context.newCommand(workflowId: workflowId))
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

private extension String {
  static func < (lhs: String, rhs: String) -> Bool {
    return lhs.compare(rhs, options: .numeric) == .orderedAscending
  }
}
