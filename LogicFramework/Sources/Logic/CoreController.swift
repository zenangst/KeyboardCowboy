import Cocoa

public protocol CoreControlling {
  func reload()
  func activate(_ keyboardShortcuts: Set<KeyboardShortcut>, rebindingWorkflows workflows: [Workflow])
  @discardableResult
  func respond(to keyboardShortcut: KeyboardShortcut) -> [Workflow]
}

public class CoreController: NSObject, CoreControlling, CommandControllingDelegate, HotkeyControllingDelegate {
  let commandController: CommandControlling
  let groupsController: GroupsControlling
  let hotkeyController: HotkeyControlling
  let keycodeMapper: KeyCodeMapping
  let rebindingController: RebindingControlling?
  let workflowController: WorkflowControlling
  let workspace: WorkspaceProviding
  var cache = [String: Int]()
  var installedApplications = [Application]()

  private(set) var currentGroups = [Group]()
  private(set) var currentKeyboardShortcuts = [KeyboardShortcut]()
  private var frontmostApplicationObserver: NSKeyValueObservation?

  public init(commandController: CommandControlling,
              groupsController: GroupsControlling,
              hotkeyController: HotkeyControlling,
              keycodeMapper: KeyCodeMapping,
              workflowController: WorkflowControlling,
              workspace: WorkspaceProviding) {
    self.cache = keycodeMapper.hashTable()
    self.commandController = commandController
    self.groupsController = groupsController
    self.hotkeyController = hotkeyController
    self.keycodeMapper = keycodeMapper
    self.rebindingController = try? RebindingController()
    self.workspace = workspace
    self.workflowController = workflowController
    super.init()
    self.commandController.delegate = self
    self.hotkeyController.delegate = self
    self.loadApplications()
    self.reload()
    frontmostApplicationObserver = NSWorkspace.shared.observe(\.frontmostApplication, options: [.new], changeHandler: { [weak self] _, _ in
      self?.reload()
    })
  }

  public func loadApplications() {
    let fileIndexer = FileIndexController(baseUrl: URL(fileURLWithPath: "/"))
    var patterns = FileIndexPatternsFactory.patterns()
    patterns.append(contentsOf: FileIndexPatternsFactory.pathExtensions())
    patterns.append(contentsOf: FileIndexPatternsFactory.lastPathComponents())

    self.installedApplications = fileIndexer.index(with: patterns, match: {
      $0.absoluteString.contains(".app")
    }, handler: { url -> Application? in
      guard let bundle = Bundle(url: url),
            let bundleIdentifier = bundle.bundleIdentifier,
            let bundleName = bundle.infoDictionary?["CFBundleName"] as? String else {
        return nil
      }
      return Application(bundleIdentifier: bundleIdentifier, bundleName: bundleName, path: bundle.bundlePath)
    })
  }

  @objc public func reload() {
    var contextRule = Rule()

    if let runningApplication = workspace.frontApplication,
       let bundleIdentifier = runningApplication.bundleIdentifier {
      contextRule.applications = installedApplications.filter({ $0.bundleIdentifier == bundleIdentifier })
    }

    if let weekDay = DateComponents().weekday,
       let day = Rule.Day(rawValue: weekDay) {
      contextRule.days = [day]
    }

    currentGroups = groupsController.filterGroups(using: contextRule)
    currentKeyboardShortcuts = []

    var rebindingWorkflows = [Workflow]()
    let topLevelKeyboardShortcuts = Set<KeyboardShortcut>(currentGroups.flatMap { group in
      group.workflows.compactMap { workflow in
        if workflow.isRebinding {
          rebindingWorkflows.append(workflow)
          return nil
        }

        return workflow.keyboardShortcuts.first
      }
    })

    activate(topLevelKeyboardShortcuts, rebindingWorkflows: rebindingWorkflows)
  }

  public func activate(_ keyboardShortcuts: Set<KeyboardShortcut>, rebindingWorkflows workflows: [Workflow]) {
    let old: [Hotkey] = Array(hotkeyController.hotkeys)
    var new = [Hotkey]()
    for keyboardShortcut in keyboardShortcuts {
      guard let keyCode = cache[keyboardShortcut.key.uppercased()] else { continue }
      let hotkey = Hotkey(keyboardShortcut: keyboardShortcut, keyCode: keyCode)
      new.append(hotkey)
    }
    let difference = new.difference(from: old)
    for diff in difference {
      switch diff {
      case .insert(_, let element, _):
        hotkeyController.register(element)
      case .remove(_, let element, _):
        hotkeyController.unregister(element)
      }
    }

    rebindingController?.monitor(workflows)
  }

  public func respond(to keyboardShortcut: KeyboardShortcut) -> [Workflow] {
    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reload), object: nil)
    perform(#selector(reload), with: nil, afterDelay: 2.0)

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
      for workflow in workflows {
        commandController.run(workflow.commands)
      }
    } else {
      activate(shortcutsToActivate, rebindingWorkflows: workflows.filter { $0.isRebinding })
    }
    return workflows
  }

  // MARK: CommandControllingDelegate

  public func commandController(_ controller: CommandController, failedRunning command: Command, commands: [Command]) {}

  public func commandController(_ controller: CommandController, runningCommand command: Command) {}

  public func commandController(_ controller: CommandController, didFinishRunning commands: [Command]) {
    reload()
  }

  // MARK: HotkeyControllingDelegate

  public func hotkeyControlling(_ controller: HotkeyController, didRegisterKeyboardShortcut: KeyboardShortcut) {}

  public func hotkeyControlling(_ controller: HotkeyController,
                                didInvokeKeyboardShortcut keyboardShortcut: KeyboardShortcut) {
    _ = respond(to: keyboardShortcut)
  }

  public func hotkeyControlling(_ controller: HotkeyController, didUnregisterKeyboardShortcut: KeyboardShortcut) {}
}
