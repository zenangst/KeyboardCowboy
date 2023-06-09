import Cocoa

final class ApplicationEngine {
  private struct Plugins {
    let activate: ActivateApplicationPlugin
    let bringToFront: BringToFrontApplicationPlugin
    let close: CloseApplicationPlugin
    let launch: LaunchApplicationPlugin
    let missionControl: MissionControlPlugin
  }

  private let windowListStore: WindowListStoring
  private let workspace: WorkspaceProviding
  private let plugins: Plugins

  init(scriptEngine: ScriptEngine,
       keyboard: KeyboardEngine,
       windowListStore: WindowListStoring,
       workspace: WorkspaceProviding) {
    self.windowListStore = windowListStore
    self.workspace = workspace
    self.plugins = Plugins(
      activate: ActivateApplicationPlugin(workspace: workspace),
      bringToFront: BringToFrontApplicationPlugin(engine: scriptEngine),
      close: CloseApplicationPlugin(workspace: workspace),
      launch: LaunchApplicationPlugin(workspace: workspace),
      missionControl: MissionControlPlugin(keyboard: keyboard)
    )
  }

  func run(_ command: ApplicationCommand) async throws {
    if command.modifiers.contains(.onlyIfNotRunning) {
      let bundleIdentifiers = self.workspace.applications.compactMap({ $0.bundleIdentifier })
      if bundleIdentifiers.contains(command.application.bundleIdentifier) {
        return
      }
    }

    switch command.action {
    case .open:
      try await openApplication(command: command)
    case .close:
      try plugins.close.execute(command)
    }
  }

  private func openApplication(command: ApplicationCommand) async throws {
    if await KeyboardCowboy.bundleIdentifier == command.application.bundleIdentifier {
      await MainActor.run {
        NotificationCenter.default.post(Notification(name: Notification.Name("OpenMainWindow")))
      }
      return
    }

    if command.modifiers.contains(.background) ||
        command.application.metadata.isElectron {
      try await plugins.launch.execute(command)
      return
    }

    try Task.checkCancellation()

    let isFrontMostApplication = command.application
      .bundleIdentifier == workspace.frontApplication?.bundleIdentifier

    if isFrontMostApplication {
      do {
        try await plugins.activate.execute(command)
        if !windowListStore.windowOwners().contains(command.application.bundleName) {
          try await plugins.launch.execute(command)
        } else {
          try await plugins.bringToFront.execute()
        }
      } catch {
        try await plugins.bringToFront.execute()
      }
    } else {
      try await plugins.launch.execute(command)

      if !windowListStore.windowOwners().contains(command.application.bundleName) {
        try await plugins.activate.execute(command)
      }

      plugins.missionControl.execute()
    }
  }
}
