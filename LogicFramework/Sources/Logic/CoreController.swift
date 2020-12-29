import BridgeKit
import Cocoa
import Combine
import ModelKit

public protocol CoreControlling: AnyObject {
  var publisher: Published<[KeyboardShortcut]>.Publisher { get }
  var commandController: CommandControlling { get }
  var groupsController: GroupsControlling { get }
  var groups: [Group] { get }
  var installedApplications: [Application] { get }
  func setState(_ newState: CoreControllerState)
  func reloadContext()
  func activate(workflows: [Workflow])
  @discardableResult
  func respond(to keyboardShortcut: KeyboardShortcut) -> [Workflow]
  func intercept(_ context: HotKeyContext)
}

public enum CoreControllerState {
  case disabled
  case enabled
  case recording
}

public final class CoreController: NSObject, CoreControlling,
                                   CommandControllingDelegate,
                                   GroupsControllingDelegate,
                                   HotKeyControllingDelegate {
  private var transportController = TransportController.shared
  public let commandController: CommandControlling
  public let keyboardController: KeyboardCommandControlling
  public let groupsController: GroupsControlling
  let keyboardShortcutValidator: KeyboardShortcutValidator
  var hotKeyController: HotKeyControlling?
  let workflowController: WorkflowControlling
  let workspace: WorkspaceProviding
  var cache = [String: Int]()

  public var installedApplications = [Application]()
  public var groups: [Group] { return groupsController.groups }

  private var resetInterval: TimeInterval = 2.0
  private(set) var currentGroups = [Group]()
  private(set) var currentKeyboardShortcuts = [KeyboardShortcut]()
  @Published public var currentKeyboardSequence = [KeyboardShortcut]()
  public var publisher: Published<[KeyboardShortcut]>.Publisher { $currentKeyboardSequence }
  private var activeWorkflows = [Workflow]()
  private var frontmostApplicationObserver: NSKeyValueObservation?
  private var state: CoreControllerState = .disabled

  public init(_ initialState: CoreControllerState,
              commandController: CommandControlling,
              groupsController: GroupsControlling,
              hotKeyController: HotKeyControlling?,
              installedApplications: [Application],
              keyboardCommandController: KeyboardCommandControlling,
              keyboardShortcutValidator: KeyboardShortcutValidator,
              keycodeMapper: KeyCodeMapping,
              workflowController: WorkflowControlling,
              workspace: WorkspaceProviding) {
    self.cache = keycodeMapper.hashTable()
    self.commandController = commandController
    self.groupsController = groupsController
    self.installedApplications = installedApplications
    self.hotKeyController = hotKeyController
    self.keyboardController = keyboardCommandController
    self.keyboardShortcutValidator = keyboardShortcutValidator
    self.workflowController = workflowController
    self.workspace = workspace
    super.init()
    self.hotKeyController?.delegate = self
    self.commandController.delegate = self
    self.reloadContext()
    frontmostApplicationObserver = NSWorkspace.shared.observe(
      \.frontmostApplication,
      options: [.new], changeHandler: { [weak self] _, _ in self?.reloadContext() })

    self.state = initialState
    self.groupsController.delegate = self

    setState(initialState)
  }

  public func setState(_ newState: CoreControllerState) {
    state = newState

    switch state {
    case .disabled:
      hotKeyController?.isEnabled = false
    case .enabled, .recording:
      hotKeyController?.isEnabled = true
    }
  }

  @objc public func reloadContext() {
    NSObject.cancelPreviousPerformRequests(
      withTarget: self,
      selector: #selector(reloadContext),
      object: nil)
    Debug.print("🪀 Reloading context")
    var contextRule = Rule()

    if let runningApplication = workspace.frontApplication,
       let bundleIdentifier = runningApplication.bundleIdentifier {
      contextRule.bundleIdentifiers = installedApplications
        .compactMap({ $0.bundleIdentifier })
        .filter({ $0 == bundleIdentifier })
    }

    if let weekDay = DateComponents().weekday,
       let day = Rule.Day(rawValue: weekDay) {
      contextRule.days = [day]
    }

    currentGroups = groupsController.filterGroups(using: contextRule)
    currentKeyboardShortcuts = []
    activate(workflows: currentGroups.flatMap({ $0.workflows }))
  }

  public func activate(workflows: [Workflow]) {
    activeWorkflows = workflows
  }

  public func respond(to keyboardShortcut: KeyboardShortcut) -> [Workflow] {
    perform(#selector(reloadContext), with: nil, afterDelay: resetInterval)

    currentKeyboardShortcuts.append(keyboardShortcut)
    let workflows = workflowController.filterWorkflows(
      from: currentGroups,
      keyboardShortcuts: currentKeyboardShortcuts)

    let currentCount = currentKeyboardShortcuts.count
    var shortcutsToActivate = Set<KeyboardShortcut>()
    var workflowsToActivate = Set<Workflow>()
    for workflow in workflows where workflow.keyboardShortcuts.count >= currentCount {
      guard let validShortcut = workflow.keyboardShortcuts[currentCount..<workflow.keyboardShortcuts.count].first
      else { continue }
      workflowsToActivate.insert(workflow)
      shortcutsToActivate.insert(validShortcut)
    }

    if currentCount == 1 {
      currentKeyboardSequence = []
    }

    currentKeyboardSequence.append(keyboardShortcut)
    if workflows.count == 1 && shortcutsToActivate.isEmpty {
      currentKeyboardSequence.append(KeyboardShortcut(key: "="))
      for workflow in workflows {
        currentKeyboardSequence.append(KeyboardShortcut(key: "\(workflow.name)"))
        commandController.run(workflow.commands)
      }
      reloadContext()
    } else {
      let workflowNames = workflowsToActivate.compactMap({ $0.name })
      Debug.print("🪃 Activating: \(workflowNames.joined(separator: ", ").replacingOccurrences(of: "Open ", with: ""))")
      activate(workflows: Array(workflowsToActivate))
    }

    NSObject.cancelPreviousPerformRequests(withTarget: self,
                                           selector: #selector(resetKeyboardSequence),
                                           object: nil)
    perform(#selector(resetKeyboardSequence), with: nil, afterDelay: resetInterval)

    return workflows
  }

  public func intercept(_ context: HotKeyContext) {
    let counter = currentKeyboardShortcuts.count
    for workflow in activeWorkflows where counter < workflow.keyboardShortcuts.count {
      guard !workflow.keyboardShortcuts.isEmpty else { continue }

      // Verify that the current key code is in the list of cached keys.
      let keyboardShortcut = workflow.keyboardShortcuts[counter]
      guard let shortcutKeyCode = self.cache[keyboardShortcut.key.uppercased()],
            context.keyCode == shortcutKeyCode else { continue }

      // Check if the events modifier flags is a match for the current keyboard shortcut
      var modifiersMatch: Bool = true
      if let modifiers = keyboardShortcut.modifiers {
        modifiersMatch = context.event.flags.isEqualTo(modifiers)
      } else {
        modifiersMatch = context.event.flags.isEmpty
      }

      guard modifiersMatch else { continue }

      context.result = nil

      if keyboardShortcut == workflow.keyboardShortcuts.last {
        if case .keyboard(let command) = workflow.commands.last {
          _ = keyboardController.run(command, type: context.type, eventSource: context.eventSource)
        } else if context.type == .keyDown {
          Debug.print("⌨️ Workflow: \(workflow.name): \(currentKeyboardSequence)")
          _ = respond(to: keyboardShortcut)
        }
      } else if context.type == .keyDown {
        _ = respond(to: keyboardShortcut)
      }

      break
    }
  }

  @objc private func resetKeyboardSequence() {
    currentKeyboardSequence = []
  }

  private func record(_ context: HotKeyContext) {
    setState(.enabled)
    guard context.type == .keyDown else { return }

    let validationContext = keyboardShortcutValidator.validate(context)
    TransportController.shared.send(validationContext)
    context.result = nil
  }

  // MARK: HotKeyControllingDelegate

  public func hotKeyController(_ controller: HotKeyControlling, didReceiveContext context: HotKeyContext) {
    switch state {
    case .enabled:
      intercept(context)
    case .recording:
      record(context)
    case .disabled:
      break
    }
  }

  // MARK: CommandControllingDelegate

  public func commandController(_ controller: CommandController, failedRunning command: Command, commands: [Command]) {
    Debug.print("🛑 Failed running: \(command)")
  }

  public func commandController(_ controller: CommandController, runningCommand command: Command) {
    Debug.print("🏃‍♂️ Running running: \(command)")
  }

  public func commandController(_ controller: CommandController, didFinishRunning commands: [Command]) {
    reloadContext()
    Debug.print("✅ Finished running: \(commands)")
  }

  // MARK: GroupsControllingDelegate

  public func groupsController(_ controller: GroupsControlling, didReloadGroups groups: [Group]) {
    reloadContext()
  }
}
