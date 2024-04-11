import Cocoa

final class ApplicationCommandRunner: @unchecked Sendable {
  private struct Plugins {
    let activate: ActivateApplicationPlugin
    let bringToFront: BringToFrontApplicationPlugin
    let close: CloseApplicationPlugin
    let launch: LaunchApplicationPlugin
  }

  private let workspace: WorkspaceProviding
  private let plugins: Plugins

  init(scriptCommandRunner: ScriptCommandRunner, keyboard: KeyboardCommandRunner, workspace: WorkspaceProviding) {
    self.workspace = workspace
    self.plugins = Plugins(
      activate: ActivateApplicationPlugin(),
      bringToFront: BringToFrontApplicationPlugin(scriptCommandRunner),
      close: CloseApplicationPlugin(workspace: workspace),
      launch: LaunchApplicationPlugin(workspace: workspace)
    )
  }

  func run(_ command: ApplicationCommand, checkCancellation: Bool) async throws {
    if command.modifiers.contains(.onlyIfNotRunning) {
      let bundleIdentifiers = self.workspace.applications.compactMap(\.bundleIdentifier)
      if bundleIdentifiers.contains(command.application.bundleIdentifier) {
        return
      }
    }

    switch command.action {
    case .open:  try await openApplication(command, checkCancellation: checkCancellation)
    case .close: try plugins.close.execute(command, checkCancellation: checkCancellation)
    case .hide:  try await hideApplication(command)
    }
  }

  private func openApplication(_ command: ApplicationCommand, checkCancellation: Bool) async throws {
    let bundleIdentifier = command.application.bundleIdentifier
    let bundleName = command.application.bundleName

    if let customRoutine = CustomApplicationRoutine(rawValue: bundleIdentifier)?.routine() {
      if await customRoutine.run() { return }
    }

    let isBackgroundOrElectron = command.modifiers.contains(.background) || command.application.metadata.isElectron

    if isBackgroundOrElectron {
      try await plugins.launch.execute(command, checkCancellation: checkCancellation)
      return
    }

    if checkCancellation { try Task.checkCancellation() }

    let isFrontMostApplication = bundleIdentifier == workspace.frontApplication?.bundleIdentifier

    if isFrontMostApplication {
      do {
        try await plugins.activate.execute(command, checkCancellation: checkCancellation)
        if await !WindowStore.shared.windows.map(\.ownerName).contains(bundleName) {
          try await plugins.launch.execute(command, checkCancellation: checkCancellation)
        } else {
          try await plugins.bringToFront.execute(checkCancellation: checkCancellation)
        }
      } catch {
        try await plugins.bringToFront.execute(checkCancellation: checkCancellation)
      }
    } else {
      try await plugins.launch.execute(command, checkCancellation: checkCancellation)
      if await !WindowStore.shared.windows.map(\.ownerName).contains(bundleName) {
        try? await plugins.activate.execute(command, checkCancellation: checkCancellation)
      }
    }
  }

  private func hideApplication(_ command: ApplicationCommand) async throws {
    guard let runningApplication = self.workspace.applications.first(where: { $0.bundleIdentifier == command.application.bundleIdentifier }) else {
      return
    }

    UserSpace.shared.frontMostApplication.ref.activate()
    _ = runningApplication.hide()
  }
}
