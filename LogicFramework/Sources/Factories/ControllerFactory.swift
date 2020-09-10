import Cocoa

public class ControllerFactory {
  public func commandController(
    applicationCommandController: ApplicationCommandControlling? = nil
  ) -> CommandControlling {
    let applicationCommandController = applicationCommandController ??
      self.applicationCommandController(
        windowListProvider: WindowListProvider(),
        workspace: NSWorkspace.shared)
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
