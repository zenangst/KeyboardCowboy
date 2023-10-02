import Foundation
import AppKit
import Carbon
import Combine
import MachPort

protocol CommandRunning {
  func serialRun(_ commands: [Command])
  func concurrentRun(_ commands: [Command])
}

final class CommandRunner: CommandRunning {
  struct Runners {
    let application: ApplicationCommandRunner
    let keyboard: KeyboardCommandRunner
    let menubar: MenuBarCommandRunner
    let open: OpenCommandRunner
    let script: ScriptCommandRunner
    let shortcut: ShortcutsCommandRunner
    let system: SystemCommandRunner
    let type: TypeCommandRunner
    let window: WindowCommandRunner
  }

  var machPort: MachPortEventController? {
    didSet {
      runners.keyboard.machPort = machPort
      runners.system.machPort = machPort
      if let machPort {
        runners.system.subscribe(to: machPort.$flagsChanged)
        runners.window.subscribe(to: machPort.$event)
        subscribe(to: machPort.$event)
      }
    }
  }

  private let missionControl: MissionControlPlugin
  private let workspace: WorkspaceProviding
  private var serialTask: Task<Void, Error>?
  private var concurrentTask: Task<Void, Error>?
  private var subscription: AnyCancellable?

  let runners: Runners

  @MainActor
  var lastExecutedCommand: Command?
  var eventSource: CGEventSource?

  init(_ workspace: WorkspaceProviding = NSWorkspace.shared,
       applicationStore: ApplicationStore,
       scriptCommandRunner: ScriptCommandRunner,
       keyboardCommandRunner: KeyboardCommandRunner) {
    let systemCommandRunner = SystemCommandRunner(applicationStore)
    self.missionControl = MissionControlPlugin(keyboard: keyboardCommandRunner)
    self.runners = .init(
      application: ApplicationCommandRunner(
        scriptCommandRunner: scriptCommandRunner,
        keyboard: keyboardCommandRunner,
        windowListStore: WindowListStore(),
        workspace: workspace
      ),
      keyboard: keyboardCommandRunner,
      menubar: MenuBarCommandRunner(),
      open: OpenCommandRunner(scriptCommandRunner, workspace: workspace),
      script: scriptCommandRunner,
      shortcut: ShortcutsCommandRunner(scriptCommandRunner),
      system: systemCommandRunner,
      type: TypeCommandRunner(keyboardCommandRunner),
      window: WindowCommandRunner()
    )
    self.workspace = workspace
  }

  func reveal(_ commands: [Command]) {
    missionControl.dismissIfActive()
    for command in commands {
      switch command {
      case .application(let applicationCommand):
        workspace.reveal(applicationCommand.application.path)
      case .open(let openCommand):
        workspace.reveal(openCommand.path)
      case .script(let scriptCommand):
        if case .path(let path) = scriptCommand.source {
          workspace.reveal(path)
        }
      case .shortcut(let shortcut):
        Task(priority: .userInitiated) {
          let source = """
          shortcuts view "\(shortcut.shortcutIdentifier)"
          """
          let shellScript = ScriptCommand(name: "Reveal \(shortcut.shortcutIdentifier)",
                                          kind: .shellScript, source: .inline(source), notification: false)

          _ = try await runners.script.run(shellScript)
        }
      case .builtIn, .keyboard, .type,
          .systemCommand, .menuBar, .windowManagement:
        break
      }
    }
  }

  func serialRun(_ commands: [Command]) {
    missionControl.dismissIfActive()
    serialTask?.cancel()
    serialTask = Task.detached(priority: .userInitiated) { [weak self] in
      guard let self else { return }
      do {
        for command in commands {
          try Task.checkCancellation()
          do {
            try await self.run(command)
          } catch { }
          if let delay = command.delay {
            try await Task.sleep(for: .milliseconds(delay))
          }
        }
      }
    }
  }

  func concurrentRun(_ commands: [Command]) {
    missionControl.dismissIfActive()
    concurrentTask?.cancel()
    concurrentTask = Task.detached(priority: .userInitiated) { [weak self] in
      guard let self else { return }
      for command in commands {
        do {
          try Task.checkCancellation()
          try await self.run(command)
        } catch { }
      }
    }
  }

  func run(_ command: Command) async throws {
    do {
      let output: String
      switch command {
      case .application(let applicationCommand):
        try await runners.application.run(applicationCommand)
        output = command.name
      case .builtIn(let builtInCommand):
        switch builtInCommand.kind {
        case .quickRun:
          break
        case .recordSequence:
          break
        case .repeatLastKeystroke:
          break
        }
        output = command.name
      case .keyboard(let keyboardCommand):
        try runners.keyboard.run(keyboardCommand,
                                 type: .keyDown,
                                 originalEvent: nil,
                                 with: eventSource)
        try runners.keyboard.run(keyboardCommand,
                                 type: .keyUp,
                                 originalEvent: nil,
                                 with: eventSource)
        try await Task.sleep(for: .milliseconds(1))
        output = command.name
      case .menuBar(let menuBarCommand):
        try await runners.menubar.execute(menuBarCommand)
        output = command.name
      case .open(let openCommand):
        try await runners.open.run(openCommand)
        output = command.name
      case .script(let scriptCommand):
        let result = try await self.runners.script.run(scriptCommand)
        if let result = result {
          let trimmedResult = result.trimmingCharacters(in: .newlines)
          output = command.name + " " + trimmedResult
        } else {
          output = command.name
        }
      case .shortcut(let shortcutCommand):
        let result = try await runners.shortcut.run(shortcutCommand)
        if let result = result {
          let trimmedResult = result.trimmingCharacters(in: .newlines)
          output = command.name + " " + trimmedResult
        } else {
          output = command.name
        }
      case .type(let typeCommand):
        try await runners.type.run(typeCommand)
        output = command.name
      case .systemCommand(let systemCommand):
        try await runners.system.run(systemCommand)
        output = command.name
      case .windowManagement(let windowCommand):
        try await runners.window.run(windowCommand)
        output = ""
      }

      if command.notification, !output.isEmpty {
        await MainActor.run {
          lastExecutedCommand = command
          BezelNotificationController.shared.post(.init(text: output))
        }
      }
    } catch {
      throw error
    }
  }

  private func subscribe(to publisher: Published<MachPortEvent?>.Publisher) {
    subscription = publisher
      .compactMap { $0 }
      .sink { [weak self] machPortEvent in
        let emptyFlags = machPortEvent.event.flags == CGEventFlags.maskNonCoalesced

        guard machPortEvent.keyCode == kVK_Escape,
              machPortEvent.type == .keyDown,
              emptyFlags else {
          return
        }

        self?.concurrentTask?.cancel()
        self?.serialTask?.cancel()
      }
  }
}
