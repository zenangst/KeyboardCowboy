import Cocoa

protocol ApplicationCommandRunnerDelegate: AnyObject {
  func applicationCommandRunnerWillRunApplicationCommand(_ command: ApplicationCommand)
}

final class ApplicationCommandRunner: @unchecked Sendable {
  private struct Plugins {
    let activate: ActivateApplicationPlugin
    let bringToFront: BringToFrontApplicationPlugin
    let close: CloseApplicationPlugin
    let hide: HideApplicationPlugin
    let unhide: UnhideApplicationPlugin
    let launch: LaunchApplicationPlugin
  }

  var delegate: ApplicationCommandRunnerDelegate?

  private let workspace: WorkspaceProviding
  private let plugins: Plugins

  @MainActor
  init(scriptCommandRunner: ScriptCommandRunner = .init(),
       keyboard: KeyboardCommandRunner,
       workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.workspace = workspace
    self.plugins = Plugins(
      activate: ActivateApplicationPlugin(),
      bringToFront: BringToFrontApplicationPlugin(scriptCommandRunner),
      close: CloseApplicationPlugin(workspace: workspace),
      hide: HideApplicationPlugin(workspace: workspace, userSpace: .shared),
      unhide: UnhideApplicationPlugin(workspace: workspace, userSpace: .shared),
      launch: LaunchApplicationPlugin(workspace: workspace)
    )
  }

  func run(_ command: ApplicationCommand, checkCancellation: Bool) async throws {
    delegate?.applicationCommandRunnerWillRunApplicationCommand(command)
    if command.modifiers.contains(.onlyIfNotRunning) {
      let bundleIdentifiers = self.workspace.applications.compactMap(\.bundleIdentifier)
      if bundleIdentifiers.contains(command.application.bundleIdentifier) {
        return
      }
    }

    if await command.application.bundleIdentifier == KeyboardCowboy.bundleIdentifier {
      await NSApplication.shared.delegate?.applicationDidBecomeActive?(.openKeyboardCowboy)
    }

    switch command.action {
    case .open:  try await openApplication(command, checkCancellation: checkCancellation)
    case .close: try plugins.close.execute(command, checkCancellation: checkCancellation)
    case .hide:  plugins.hide.execute(command)
    case .unhide: plugins.unhide.execute(command)
    }
  }

  // MARK: Private methods

  private func openApplication(_ command: ApplicationCommand, checkCancellation: Bool) async throws {
    let bundleIdentifier = command.application.bundleIdentifier
    let bundleName = command.application.bundleName

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
}
