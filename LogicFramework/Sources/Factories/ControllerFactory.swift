import Cocoa

public class ControllerFactory {
  public func commandController(
    applicationCommandController: ApplicationCommandControlling? = nil,
    openCommandController: OpenCommandControlling? = nil
  ) -> CommandControlling {
    let workspace = NSWorkspace.shared
    let applicationCommandController = applicationCommandController ??
      self.applicationCommandController(
        windowListProvider: WindowListProvider(),
        workspace: workspace)
    let openCommandController = openCommandController ?? self.openCommandController(workspace: workspace)

    return CommandController(applicationCommandController: applicationCommandController,
                             openCommandController: openCommandController)
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
