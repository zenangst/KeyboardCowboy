import Cocoa

public class ControllerFactory {
  public func commandController(
    applicationCommandController: ApplicationCommandControlling? = nil
  ) -> CommandControlling {
    let applicationCommandController = applicationCommandController ?? ApplicationCommandController()
    return CommandController(applicationCommandController: applicationCommandController)
  }

  public func applicationCommandController(windowListProvider: WindowListProviding? = nil,
                                           workspace: WorkspaceProviding = NSWorkspace.shared)
  -> ApplicationCommandControlling {
    ApplicationCommandController(
      windowListProvider: windowListProvider ?? WindowListProvider(),
      workspace: workspace)
  }
}
