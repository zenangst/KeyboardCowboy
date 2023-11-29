import Cocoa

final class ApplicationCommandRunner: @unchecked Sendable {
  private struct Plugins {
    let activate: ActivateApplicationPlugin
    let bringToFront: BringToFrontApplicationPlugin
    let close: CloseApplicationPlugin
    let launch: LaunchApplicationPlugin
  }

  private let windowListStore: WindowListStoring
  private let workspace: WorkspaceProviding
  private let plugins: Plugins

  init(scriptCommandRunner: ScriptCommandRunner,
       keyboard: KeyboardCommandRunner,
       windowListStore: WindowListStoring,
       workspace: WorkspaceProviding) {
    self.windowListStore = windowListStore
    self.workspace = workspace
    self.plugins = Plugins(
      activate: ActivateApplicationPlugin(),
      bringToFront: BringToFrontApplicationPlugin(scriptCommandRunner),
      close: CloseApplicationPlugin(workspace: workspace),
      launch: LaunchApplicationPlugin(workspace: workspace)
    )
  }

  func run(_ command: ApplicationCommand) async throws {
    if command.modifiers.contains(.onlyIfNotRunning) {
      let bundleIdentifiers = self.workspace.applications.compactMap(\.bundleIdentifier)
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
    let bundleIdentifier = command.application.bundleIdentifier
    let bundleName = command.application.bundleName

    if let customRoutine = CustomApplicationRoutine(rawValue: bundleIdentifier)?.routine() {
      if await customRoutine.run() { return }
    }

    let isBackgroundOrElectron = command.modifiers.contains(.background) || command.application.metadata.isElectron

    if isBackgroundOrElectron {
      try await plugins.launch.execute(command)
      return
    }

    try Task.checkCancellation()

    let isFrontMostApplication = bundleIdentifier == workspace.frontApplication?.bundleIdentifier

    if isFrontMostApplication {
      do {
        try await plugins.activate.execute(command)
        if !windowListStore.windowOwners().contains(bundleName) {
          try await plugins.launch.execute(command)
        } else {
          try await plugins.bringToFront.execute()
        }
      } catch {
        try await plugins.bringToFront.execute()
      }
    } else {
      try await plugins.launch.execute(command)
      if !windowListStore.windowOwners().contains(bundleName) {
        try? await plugins.activate.execute(command)
      }
    }
  }
}
