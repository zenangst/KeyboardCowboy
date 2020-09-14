import Cocoa

public class ControllerFactory {
  public init() {}

  public func commandController(
    appleScriptCommandController: AppleScriptControlling? = nil,
    applicationCommandController: ApplicationCommandControlling? = nil,
    keyboardCommandController: KeyboardCommandControlling? = nil,
    openCommandController: OpenCommandControlling? = nil,
    shellScriptCommandController: ShellScriptControlling? = nil
  ) -> CommandControlling {
    let workspace = NSWorkspace.shared
    let applicationCommandController = applicationCommandController ??
      self.applicationCommandController(
        windowListProvider: WindowListProvider(),
        workspace: workspace)
    let keyboardCommandController = keyboardCommandController ?? KeyboardCommandController()
    let openCommandController = openCommandController ?? self.openCommandController(workspace: workspace)
    let appleScriptCommandController = appleScriptCommandController ?? AppleScriptController()
    let shellScriptCommandController = shellScriptCommandController ?? ShellScriptController()

    return CommandController(appleScriptCommandController: appleScriptCommandController,
                             applicationCommandController: applicationCommandController,
                             keyboardCommandController: keyboardCommandController,
                             openCommandController: openCommandController,
                             shellScriptCommandController: shellScriptCommandController)
  }

  public func applicationCommandController(windowListProvider: WindowListProviding? = nil,
                                           workspace: WorkspaceProviding = NSWorkspace.shared)
  -> ApplicationCommandControlling {
    ApplicationCommandController(
      windowListProvider: windowListProvider ?? WindowListProvider(),
      workspace: workspace)
  }

  public func openCommandController(workspace: WorkspaceProviding = NSWorkspace.shared) -> OpenCommandControlling {
    OpenCommandController(workspace: workspace)
  }
}
