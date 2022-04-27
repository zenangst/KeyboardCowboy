import Combine
import Cocoa
import Foundation

@MainActor
final class KeyboardCowboyEngine {

  private var subscriptions = Set<AnyCancellable>()

  private let bundleIdentifier = Bundle.main.bundleIdentifier!
  private let commandEngine: CommandEngine
  private let workflowEngine: WorkflowEngine

  init(_ contentStore: ContentStore, workspace: NSWorkspace = .shared) {
    self.commandEngine = .init(workspace)
    self.workflowEngine = .init(
      applicationStore: contentStore.applicationStore,
      configStore: contentStore.configurationStore
    )
    subscribe(to: workspace)
  }

  func run(_ commands: [Command], serial: Bool) {
    if serial {
      commandEngine.serialRun(commands)
    } else {
      commandEngine.concurrentRun(commands)
    }
  }

  func reveal(_ commands: [Command]) {
    commandEngine.reveal(commands)
  }

  // MARK: Private methods

  private func subscribe(to workspace: NSWorkspace) {
    workspace.publisher(for: \.frontmostApplication)
      .compactMap { $0 }
      .sink { [weak self] application in
        self?.reload(with: application)
      }
      .store(in: &subscriptions)
  }

  private func reload(with application: NSRunningApplication) {
//    let newPolicy: NSApplication.ActivationPolicy
//    if application.bundleIdentifier == bundleIdentifier {
//      // TODO: Disable key bindings
//      newPolicy = .regular
//    } else {
//      newPolicy = .accessory
//    }

//    NSApplication.shared.setActivationPolicy(newPolicy)
  }
}
