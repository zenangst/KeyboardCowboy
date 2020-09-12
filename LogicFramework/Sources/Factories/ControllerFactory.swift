import Cocoa

public class ControllerFactory {
  public init() {}

  public func commandController(
    applicationCommandController: ApplicationCommandControlling? = nil,
    openCommandController: OpenCommandControlling? = nil,
    scriptCommandController: ScriptCommandControlling? = nil
  ) -> CommandControlling {
    let workspace = NSWorkspace.shared
    let applicationCommandController = applicationCommandController ??
      self.applicationCommandController(
        windowListProvider: WindowListProvider(),
        workspace: workspace)
    let openCommandController = openCommandController ?? self.openCommandController(workspace: workspace)
    let scriptCommandController = scriptCommandController ?? self.scriptCommandController()

    return CommandController(applicationCommandController: applicationCommandController,
                             openCommandController: openCommandController,
                             scriptCommandController: scriptCommandController)
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

  public func scriptCommandController(appleScriptController: AppleScriptControlling? = nil,
                                      shellScriptController: ShellScriptControlling? = nil)
  -> ScriptCommandControlling {
    ScriptCommandController(appleScriptController: appleScriptController ?? AppleScriptController(),
                            shellScriptController: shellScriptController ?? ShellScriptController())
  }
}
