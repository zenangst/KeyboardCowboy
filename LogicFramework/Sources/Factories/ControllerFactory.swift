import Cocoa
import ModelKit

public class ControllerFactory {
  public init() {}

  public func coreController(commandController: CommandControlling? = nil,
                             disableKeyboardShortcuts: Bool,
                             groupsController: GroupsControlling? = nil,
                             hotkeyController: HotkeyControlling? = nil,
                             keycodeMapper: KeyCodeMapping? = nil,
                             workflowController: WorkflowControlling? = nil,
                             workspace: WorkspaceProviding = NSWorkspace.shared) -> CoreControlling {
    let commandController = commandController ?? self.commandController()
    let groupsController = groupsController ?? GroupsController(groups: [])
    let hotkeyController = hotkeyController ?? HotkeyController(hotkeyHandler: HotkeyHandler.shared)
    let keycodeMapper = keycodeMapper ?? KeyCodeMapper()
    let workflowController = workflowController ?? WorkflowController()
    return CoreController(commandController: commandController,
                          disableKeyboardShortcuts: disableKeyboardShortcuts,
                          groupsController: groupsController,
                          hotkeyController: hotkeyController,
                          keycodeMapper: keycodeMapper,
                          workflowController: workflowController,
                          workspace: workspace)
  }

  public func hotkeyController() -> HotkeyControlling {
    HotkeyController(hotkeyHandler: HotkeyHandler.shared)
  }

  public func groupsController(groups: [Group]) -> GroupsControlling {
    GroupsController(groups: groups)
  }

  public func workflowController() -> WorkflowControlling {
    WorkflowController()
  }

  public func storageController(path: String, fileName: String = "config.json") -> StorageControlling {
    StorageController(path: path, fileName: fileName)
  }

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
