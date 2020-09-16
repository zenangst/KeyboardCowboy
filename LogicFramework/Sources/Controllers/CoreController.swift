import Foundation

public protocol CoreControlling {
  func reload()
  func activate(_ keyboardShortcuts: Set<KeyboardShortcut>)
  @discardableResult
  func respondTo(_ keyboardShortcut: KeyboardShortcut) -> [Workflow]
}

public class CoreController: CoreControlling, HotkeyControllingDelegate {
  let commandController: CommandControlling
  let groupsController: GroupsControlling
  let hotkeyController: HotkeyControlling
  let keycodeMapper: KeyCodeMapping
  let workflowController: WorkflowControlling
  let workspace: WorkspaceProviding
  var cache = [String: Int]()

  private(set) var currentGroups = [Group]()
  private(set) var currentKeyboardShortcuts = [KeyboardShortcut]()

  public init(commandController: CommandControlling,
              groupsController: GroupsControlling,
              keycodeMapper: KeyCodeMapping,
              hotkeyController: HotkeyControlling? = nil,
              workflowController: WorkflowControlling,
              workspace: WorkspaceProviding) {
    self.commandController = commandController
    self.groupsController = groupsController
    self.keycodeMapper = keycodeMapper
    self.hotkeyController = hotkeyController ?? HotkeyController.shared
    self.workspace = workspace
    self.workflowController = workflowController
    self.cache = keycodeMapper.hashTable()
    (hotkeyController ?? HotkeyController.shared).delegate = self
    self.reload()
  }

  public func reload() {
    var contextRule = Rule()

    if let runningApplication = workspace.frontApplication,
       let bundleIdentifier = runningApplication.bundleIdentifier {
      contextRule.applications = [
        Application(bundleIdentifier: bundleIdentifier, bundleName: "", path: "")
      ]
    }

    if let weekDay = DateComponents().weekday,
       let day = Rule.Day(rawValue: weekDay) {
      contextRule.days = [day]
    }

    currentGroups = groupsController.filterGroups(using: contextRule)
    currentKeyboardShortcuts = []

    let topLevelKeyboardShortcuts = Set<KeyboardShortcut>(currentGroups.flatMap { group in
      group.workflows.compactMap { workflow in workflow.keyboardShortcuts.first }
    })

    activate(topLevelKeyboardShortcuts)
  }

  public func activate(_ keyboardShortcuts: Set<KeyboardShortcut>) {
    hotkeyController.unregisterAll()
    for keyboardShortcut in keyboardShortcuts {
      guard let keyCode = cache[keyboardShortcut.key] else { continue }
      let hotkey = Hotkey(keyboardShortcut: keyboardShortcut, keyCode: keyCode)
      hotkeyController.register(hotkey)
    }
  }

  public func respondTo(_ keyboardShortcut: KeyboardShortcut) -> [Workflow] {
    currentKeyboardShortcuts.append(keyboardShortcut)
    let workflows = workflowController.filterWorkflows(
      from: currentGroups,
      keyboardShortcuts: currentKeyboardShortcuts)

    let currentCount = currentKeyboardShortcuts.count
    var shortcutsToActivate = Set<KeyboardShortcut>()
    for shortcuts in workflows.compactMap({ $0.keyboardShortcuts }) where shortcuts.count >= currentCount {
      guard let validShortcut = shortcuts[currentCount..<shortcuts.count].first else { continue }
      shortcutsToActivate.insert(validShortcut)
    }

    if workflows.count == 1 && shortcutsToActivate.isEmpty {
      reload()
      for workflow in workflows {
        commandController.run(workflow.commands)
      }
    } else {
      activate(shortcutsToActivate)
    }

    return workflows
  }

  // MARK: HotkeyControllingDelegate

  public func hotkeyControlling(_ controller: HotkeyController, didRegisterKeyboardShortcut: KeyboardShortcut) {}

  public func hotkeyControlling(_ controller: HotkeyController,
                                didInvokeKeyboardShortcut keyboardShortcut: KeyboardShortcut) {
    _ = respondTo(keyboardShortcut)
  }

  public func hotkeyControlling(_ controller: HotkeyController, didUnregisterKeyboardShortcut: KeyboardShortcut) {}
}
