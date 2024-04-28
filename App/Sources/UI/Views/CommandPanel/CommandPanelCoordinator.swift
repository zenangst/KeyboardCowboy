import Cocoa
import Foundation

final class CommandPanelCoordinator: NSObject, ObservableObject, NSWindowDelegate {
  private var cache = [ScriptCommand: NSWindowController]()

  @MainActor
  func run(_ command: ScriptCommand) {
    let windowController = cache[command, default: createNewWindowController(for: command)]

    if windowController.window?.isVisible == false {
      windowController.showWindow(nil)
    }

    if cache[command] != windowController {
      cache[command] = windowController
    }
  }

  @MainActor
  private func createNewWindowController(for command: ScriptCommand) -> NSWindowController {
    let publisher = CommandPanelViewPublisher(state: .ready)
    let runner = CommandPanelRunner(plugin: ShellScriptPlugin())
    let view = CommandPanelView(publisher: publisher, command: command, action: { [runner, publisher] in
      runner.run(command, for: publisher)
    })
    let window = CommandPanel(identifier: command.id, minSize: .zero, rootView: view)
    window.delegate = self
    let windowController = NSWindowController(window: window)
    return windowController
  }

  // MARK: NSWindowDelegate

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    var updatedCache = cache
    for (script, controller) in cache {
      if controller.window == sender {
        updatedCache[script] = nil
      }
    }

    cache = updatedCache

    return true
  }
}

private final class CommandPanelRunner {
  let plugin: ShellScriptPlugin
  var task: Task<Void, Error>?

  init(plugin: ShellScriptPlugin) {
    self.plugin = plugin
  }

  @MainActor
  func run(_ command: ScriptCommand, for publisher: CommandPanelViewPublisher) {
    guard publisher.state == .running else {
      task?.cancel()
      publisher.publish(.ready)
      return
    }

    self.task?.cancel()
    let task = Task { [plugin] in
      do {
        let output: String?
        switch (command.kind, command.source) {
        case (.shellScript, .path(let source)):
          output = try plugin.executeScript(at: source, environment: [:],
                                            checkCancellation:  true)
        case (.shellScript, .inline(let script)):
          output = try plugin.executeScript(script, environment: [:],
                                            checkCancellation: true)
        default:
          // This shouldn't happend.
          assertionFailure("Not supported.")
          return
        }

        publisher.publish(.done(output ?? "No output"))
      } catch let error as ShellScriptPlugin.ShellScriptPluginError {
        let newState: CommandPanelView.CommandState
        switch error {
        case .noData:
          newState = .error(error.localizedDescription)
        case .scriptError(let scriptError):
          newState = .error(scriptError)
        }

        publisher.publish(newState)
      }
    }
    self.task = task
  }
}
