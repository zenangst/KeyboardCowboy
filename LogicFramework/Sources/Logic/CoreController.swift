import Cocoa
import ModelKit

public protocol CoreControlling: AnyObject {
  var groupsController: GroupsControlling { get }
  var disableKeyboardShortcuts: Bool { get set }
  var groups: [Group] { get }
  var installedApplications: [Application] { get }
  func reloadContext()
  func activate(workflows: [Workflow])
  @discardableResult
  func respond(to keyboardShortcut: KeyboardShortcut) -> [Workflow]
}

public class CoreController: NSObject, CoreControlling,
                             CommandControllingDelegate,
                             GroupsControllingDelegate {
  let commandController: CommandControlling
  public let groupsController: GroupsControlling
  let keycodeMapper: KeyCodeMapping
  var hotKeyController: HotKeyControlling?
  let workflowController: WorkflowControlling
  let workspace: WorkspaceProviding
  var cache = [String: Int]()
  private(set) public var installedApplications = [Application]()

  public var groups: [Group] { return groupsController.groups }
  public var disableKeyboardShortcuts: Bool {
    didSet {
      hotKeyController?.isEnabled = !disableKeyboardShortcuts
    }
  }

  private(set) var currentGroups = [Group]()
  private(set) var currentKeyboardShortcuts = [KeyboardShortcut]()
  private var frontmostApplicationObserver: NSKeyValueObservation?

  public init(commandController: CommandControlling,
              disableKeyboardShortcuts: Bool,
              groupsController: GroupsControlling,
              keyboardCommandController: KeyboardCommandControlling,
              keycodeMapper: KeyCodeMapping,
              workflowController: WorkflowControlling,
              workspace: WorkspaceProviding) {
    self.cache = keycodeMapper.hashTable()
    self.commandController = commandController
    self.disableKeyboardShortcuts = disableKeyboardShortcuts
    self.groupsController = groupsController
    self.keycodeMapper = keycodeMapper
    self.hotKeyController = try? HotKeyController(keyCodeMapper: keycodeMapper,
                                                        keyboardController: keyboardCommandController)
    self.workflowController = workflowController
    self.workspace = workspace
    super.init()
    self.hotKeyController?.coreController = self
    self.commandController.delegate = self
    self.loadApplications()
    self.reloadContext()
    frontmostApplicationObserver = NSWorkspace.shared.observe(
      \.frontmostApplication,
      options: [.new], changeHandler: { [weak self] _, _ in self?.reloadContext() })

    self.hotKeyController?.isEnabled = !disableKeyboardShortcuts
    self.groupsController.delegate = self
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
            let bundleIdentifier = bundle.bundleIdentifier else {
        return nil
      }

      var bundleName: String?
      if let cfBundleName = bundle.infoDictionary?["CFBundleName"] as? String {
        bundleName = cfBundleName
      } else if let cfBundleDisplayname = bundle.infoDictionary?["CFBundleDisplayName"] as? String {
        bundleName = cfBundleDisplayname
      }

      if bundle.infoDictionary?["CFBundleIconFile"] as? String == nil { return nil }

      guard let resolvedBundleName = bundleName else { return nil }

      return Application(bundleIdentifier: bundleIdentifier, bundleName: resolvedBundleName, path: bundle.bundlePath)
    }).sorted(by: { $0.bundleName.lowercased() < $1.bundleName.lowercased() })
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
    hotKeyController?.invocations = 0
    activate(workflows: currentGroups.flatMap({ $0.workflows }))
  }

  public func activate(workflows: [Workflow]) {
    hotKeyController?.monitor(workflows)
  }

  public func respond(to keyboardShortcut: KeyboardShortcut) -> [Workflow] {
    perform(#selector(reloadContext), with: nil, afterDelay: 2.0)

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

    if workflows.count == 1 && shortcutsToActivate.isEmpty {
      for workflow in workflows {
        commandController.run(workflow.commands)
      }
      reloadContext()
    } else {
      hotKeyController?.invocations += 1
      let workflowNames = workflowsToActivate.compactMap({ $0.name })
      Debug.print("🪃 Activating: \(workflowNames.joined(separator: ", ").replacingOccurrences(of: "Open ", with: ""))")
      activate(workflows: Array(workflowsToActivate))
    }
    return workflows
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
