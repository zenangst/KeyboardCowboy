import Carbon
import Cocoa
import Foundation

final class CommandPanelCoordinator: NSObject, ObservableObject, NSWindowDelegate {
  private var cache = [ScriptCommand.ID: NSWindowController]()

  init(cache: [ScriptCommand.ID : NSWindowController] = [ScriptCommand.ID: NSWindowController]()) {
    self.cache = cache
  }

  @MainActor
  func run(_ command: ScriptCommand) {
    let windowController = cache[command.id, default: createNewWindowController(for: command)]

    if windowController.window?.isVisible == false {
      windowController.showWindow(nil)
    }
    windowController.window?.makeKeyAndOrderFront(nil)

    if cache[command.id] != windowController {
      cache[command.id] = windowController
    }
  }

  @MainActor
  private func createNewWindowController(for command: ScriptCommand) -> NSWindowController {
    let publisher = CommandPanelViewPublisher(state: .ready)
    let runner = CommandPanelRunner(plugin: ShellScriptPlugin())
    var command = command
    let view = CommandPanelView(publisher: publisher, command: command,
                                onChange: { newContents in
      command.source = .inline(newContents)
    }, onSubmit: { _ in
      runner.run(command, for: publisher)
    }, action: { [runner, publisher] in
      runner.run(command, for: publisher)
    })
    let window = CommandPanel(identifier: command.id, runner: runner, minSize: .zero, rootView: view)
    window.eventDelegate = self
    window.delegate = self
    let windowController = NSWindowController(window: window)
    windowController.windowFrameAutosaveName = "CommandPanel-\(command.id)"
    runner.run(command, for: publisher)
    return windowController
  }

  // MARK: NSWindowDelegate

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    clearCache(sender)
    return true
  }

  @MainActor
  func clearCache(_ window: NSWindow) {
    var updatedCache = cache
    for (scriptID, controller) in cache {
      if controller.window == window {
        updatedCache[scriptID] = nil
      }
    }

    cache = updatedCache
  }
}

extension CommandPanelCoordinator: CommandPanelEventDelegate {
  // MARK: CommandPanelEventDelegate

  @MainActor
  func shouldConsumeEvent(_ event: NSEvent, for window: NSWindow, runner: CommandPanelRunner) -> Bool {
    switch Int(event.keyCode) {
    case kVK_ANSI_W:
      if event.type == .keyDown, event.modifierFlags.contains(.command) {
        runner.cancel()
        window.close()
        clearCache(window)
        return true
      }
      return false
    case kVK_Escape:
      if event.type == .keyDown {
        runner.cancel()
        window.close()
        clearCache(window)
      }
      return true
    default:
      return false
    }
  }
}

final class CommandPanelRunner {
  let plugin: ShellScriptPlugin
  var task: Task<Void, Error>?

  init(plugin: ShellScriptPlugin) {
    self.plugin = plugin
  }

  func cancel() {
    task?.cancel()
  }

  @MainActor
  func run(_ command: ScriptCommand, for publisher: CommandPanelViewPublisher) {
    if publisher.state == .running {
      task?.cancel()
      publisher.publish(.ready)
      return
    }

    self.task?.cancel()
    let task = Task(priority: .high) { [plugin] in
      publisher.publish(.running)
      let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: true)
      do {
        let output: String?
        switch (command.kind, command.source) {
        case (.shellScript, .path(let source)):
          output = try await plugin.executeScript(at: source, environment: snapshot.terminalEnvironment(),
                                                  checkCancellation:  true)
        case (.shellScript, .inline(let script)):
          output = try await plugin.executeScript(script, environment: snapshot.terminalEnvironment(),
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
