import AppKit
import SwiftUI

@MainActor
final class WindowOpener: ObservableObject {
  private let core: Core
  private lazy var windowSwitcherWindow = WindowSwitcherWindow()

  init(core: Core) {
    self.core = core

    NotificationCenter.default.addObserver(self, selector: #selector(openMainWindow), name: .openKeyboardCowboy, object: nil)
  }

  @objc func openMainWindow() {
    MainWindow(core: core).open()
  }

  func openWindowSwitcher(_ snapshot: UserSpace.Snapshot) {
    windowSwitcherWindow.open(snapshot)
  }

  func openGroup(_ context: GroupWindow.Context) {
    GroupWindow(
      context: context,
      applicationStore: ApplicationStore.shared,
      configurationPublisher: core.configCoordinator.configurationPublisher,
      contentPublisher: core.groupCoordinator.contentPublisher,
      contentCoordinator: core.groupCoordinator,
      sidebarCoordinator: core.sidebarCoordinator
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

        updater.modifyWorkflow(using: transaction) { workflow in
          let resolvedCommandId: String = commandId ?? UUID().uuidString
          var command: Command
          switch payload {
          case .placeholder:
            return
          case .builtIn(let newCommand):
            command = .builtIn(newCommand)
          case .bundled(let newCommand):
            command = .bundled(newCommand)
          case .menuBar(let tokens, let application):
            command = .menuBar(.init(id: resolvedCommandId, application: application, tokens: tokens))
          case .mouse(let kind):
            command = .mouse(.init(meta: .init(), kind: kind))
          case .keyboardShortcut(let keyShortcuts):
            command = .keyboard(.init(id: resolvedCommandId, name: "", keyboardShortcuts: keyShortcuts, notification: nil))
          case .script(let value, let kind, let scriptExtension):
            let source: ScriptCommand.Source
            switch kind {
            case .file:
              source = .path(value)
            case .source:
              source = .inline(value)
            }

            switch scriptExtension {
            case .appleScript:
              command = .script(.init(name: title, kind: .appleScript, source: source, notification: nil))
            case .shellScript:
              command = .script(.init(name: title, kind: .shellScript, source: source, notification: nil))
            }
          case .text(let textCommand):
            switch textCommand.kind {
            case .insertText(let typeCommand):
              command = .text(.init(.insertText(typeCommand)))
            }
          case .shortcut(let name):
            command = .shortcut(.init(id: resolvedCommandId, shortcutIdentifier: name,
                                      name: name, isEnabled: true, notification: nil))
          case .application(let application, let action,
                            let inBackground, let hideWhenRunning, let ifNotRunning, let waitForAppToLaunch):
            assert(application != nil)
            guard let application else {
              return
            }

            var modifiers = [ApplicationCommand.Modifier]()
            if inBackground { modifiers.append(.background) }
            if hideWhenRunning { modifiers.append(.hidden) }
            if ifNotRunning { modifiers.append(.onlyIfNotRunning) }
            if waitForAppToLaunch { modifiers.append(.waitForAppToLaunch) }

            let commandAction: ApplicationCommand.Action = switch action {
            case .close:  .close
            case .open:   .open
            case .hide:   .hide
            case .unhide: .unhide
            case .peek:   .peek
            }

            command = Command.application(.init(id: resolvedCommandId,
                                                name: title,
                                                action: commandAction,
                                                application: application,
                                                modifiers: modifiers,
                                                notification: nil))
          case .open(let path, let application):
            let resolvedPath = (path as NSString).expandingTildeInPath
            command = Command.open(.init(id: resolvedCommandId,
                                         name: "\(path)", application: application, path: resolvedPath,
                                         notification: nil))
          case .url(let targetUrl, let application):
            let urlString = targetUrl.absoluteString
            command = Command.open(.init(id: resolvedCommandId,
                                         name: "\(urlString)", application: application, path: urlString,
                                         notification: nil))
          case .systemCommand(let kind):
            command = Command.systemCommand(.init(id: UUID().uuidString,
                                                  name: "System command",
                                                  kind: kind,
                                                  notification: nil))
          case .uiElement(let predicates):
            command = Command.uiElement(.init(predicates: predicates))
          case .windowManagement(let kind):
            command = Command.windowManagement(.init(id: UUID().uuidString,
                                                     name: "Window Management Command",
                                                     kind: kind,
                                                     notification: nil,
                                                     animationDuration: 0))
          }
          workflow.updateOrAddCommand(command)
        }
        core.groupCoordinator.handle(.selectWorkflow(workflowIds: [workflowId]))
        core.groupCoordinator.handle(.refresh(groupIds))
      }
    }.open()
  }
}
