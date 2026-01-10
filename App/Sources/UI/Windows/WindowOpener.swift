import AppKit
import SwiftUI

@MainActor
final class WindowOpener: ObservableObject {
  private let core: Core
  private var mainWindow: MainWindow!
  private lazy var windowSwitcherWindow = WindowSwitcherWindow(commandRunner: core.commandRunner)

  init(core: Core) {
    self.core = core
    mainWindow = MainWindow.shared ?? MainWindow(core: core, windowOpener: self)
    NotificationCenter.default.addObserver(self, selector: #selector(openMainWindow), name: .openKeyboardCowboy, object: nil)
  }

  @objc func openMainWindow() {
    mainWindow.open()
  }

  func openWindowSwitcher(_ snapshot: UserSpace.Snapshot) {
    windowSwitcherWindow.open(snapshot)
  }

  func openPrompt(_ content: () -> some View) {
    UserPromptWindow().open(content)
  }

  func openKeyViewer() {
    KeyViewer.instance.open()
  }

  func openGroup(_ context: GroupWindow.Context) {
    GroupWindow(
      context: context,
      applicationStore: ApplicationStore.shared,
      configurationPublisher: core.configCoordinator.configurationPublisher,
      contentPublisher: core.groupCoordinator.contentPublisher,
      contentCoordinator: core.groupCoordinator,
      sidebarCoordinator: core.sidebarCoordinator,
    )
    .open(context)
  }

  func openPermissions() {
    Permissions().open()
  }

  func openReleaseNotes() {
    ReleaseNotes().open()
  }

  func openEmptyConfig() {
    EmptyConfiguration(store: core.contentStore).open()
  }

  func openNewCommandWindow(_ context: NewCommandWindow.Context) {
    NewCommandWindow(context: context,
                     contentStore: core.contentStore,
                     uiElementCaptureStore: core.uiElementCaptureStore,
                     configurationPublisher: core.configCoordinator.configurationPublisher) { [core] workflowId, commandId, title, payload in
      let groupIds = core.groupSelection.selections
      Task {
        let transaction = core.workflowCoordinator.updateTransaction
        let updater = core.configurationUpdater

        var payload = payload
        if case let .systemCommand(kind) = payload {
          payload = switch kind {
          case .activateLastApplication: .systemCommand(kind: .activateLastApplication)
          case .applicationWindows: .systemCommand(kind: .applicationWindows)
          case .fillAllOpenWindows: .systemCommand(kind: .fillAllOpenWindows)
          case .hideAllApps: .systemCommand(kind: .hideAllApps)
          case .minimizeAllOpenWindows: .systemCommand(kind: .minimizeAllOpenWindows)
          case .missionControl: .systemCommand(kind: .missionControl)
          case .showDesktop: .systemCommand(kind: .showDesktop)
          case .showNotificationCenter: .systemCommand(kind: .showNotificationCenter)
          }
        }

        updater.modifyWorkflow(using: transaction) { workflow in
          let resolvedCommandId: String = commandId ?? UUID().uuidString
          var command: Command
          switch payload {
          case .placeholder:
            return
          case let .builtIn(newCommand):
            command = .builtIn(newCommand)
          case let .bundled(newCommand):
            workflow.execution = .serial
            command = .bundled(newCommand)
          case let .menuBar(tokens, application):
            command = .menuBar(.init(id: resolvedCommandId, application: application, tokens: tokens))
          case let .mouse(kind):
            command = .mouse(.init(meta: .init(), kind: kind))
          case let .keyboardShortcut(keyShortcuts):
            command = .keyboard(.init(id: resolvedCommandId, name: "", kind: .key(command: .init(keyboardShortcuts: keyShortcuts, iterations: 1)), notification: nil))
          case let .inputSource(id, name):
            command = .keyboard(.init(name: resolvedCommandId, kind: .inputSource(command: .init(inputSourceId: id, name: name))))
          case let .script(value, kind, scriptExtension):
            let source: ScriptCommand.Source = switch kind {
            case .file:
              .path(value)
            case .source:
              .inline(value)
            }

            switch scriptExtension {
            case .appleScript:
              command = .script(.init(name: title, kind: .appleScript(variant: .regular), source: source, notification: nil))
            case .shellScript:
              command = .script(.init(name: title, kind: .shellScript, source: source, notification: nil))
            }
          case let .text(textCommand):
            switch textCommand.kind {
            case let .insertText(typeCommand):
              command = .text(.init(.insertText(typeCommand)))
            }
          case let .shortcut(name):
            command = .shortcut(.init(id: resolvedCommandId, shortcutIdentifier: name,
                                      name: name, isEnabled: true, notification: nil))
          case let .application(application, action,
                                inBackground, hideWhenRunning, ifNotRunning, waitForAppToLaunch, addToStage):
            assert(application != nil)
            guard let application else {
              return
            }

            var modifiers = [ApplicationCommand.Modifier]()
            if inBackground { modifiers.append(.background) }
            if hideWhenRunning { modifiers.append(.hidden) }
            if ifNotRunning { modifiers.append(.onlyIfNotRunning) }
            if waitForAppToLaunch { modifiers.append(.waitForAppToLaunch) }
            if addToStage { modifiers.append(.addToStage) }

            let commandAction: ApplicationCommand.Action = switch action {
            case .close: .close
            case .open: .open
            case .hide: .hide
            case .unhide: .unhide
            case .peek: .peek
            }

            command = Command.application(.init(id: resolvedCommandId,
                                                name: title,
                                                action: commandAction,
                                                application: application,
                                                modifiers: modifiers,
                                                notification: nil))
          case let .open(path, application):
            let resolvedPath = (path as NSString).expandingTildeInPath
            command = Command.open(.init(id: resolvedCommandId,
                                         name: "\(path)", application: application, path: resolvedPath,
                                         notification: nil))
          case let .url(targetUrl, application):
            let urlString = targetUrl.absoluteString
            command = Command.open(.init(id: resolvedCommandId,
                                         name: "\(urlString)", application: application, path: urlString,
                                         notification: nil))
          case let .systemCommand(kind):
            command = Command.systemCommand(.init(id: resolvedCommandId,
                                                  name: "System command",
                                                  kind: kind,
                                                  notification: nil))
          case let .uiElement(predicates):
            command = Command.uiElement(.init(meta: Command.MetaData(id: resolvedCommandId), predicates: predicates))
          case let .windowFocus(kind):
            command = Command.windowFocus(.init(kind: kind, meta: Command.MetaData(id: resolvedCommandId)))
          case let .windowManagement(kind):
            command = Command.windowManagement(.init(id: resolvedCommandId,
                                                     name: "Window Management Command",
                                                     kind: kind,
                                                     notification: nil,
                                                     animationDuration: 0))
          case let .windowTiling(kind):
            command = Command.windowTiling(.init(kind: kind, meta: Command.MetaData()))
          }
          workflow.updateOrAddCommand(command)
        }
        core.groupCoordinator.handle(.selectWorkflow(workflowIds: [workflowId]))
        core.groupCoordinator.handle(.refresh(groupIds))
      }
    }.open()
  }
}
