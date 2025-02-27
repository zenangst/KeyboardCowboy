import AppKit
import SwiftUI

@MainActor
final class WindowOpener: ObservableObject {
  private let core: Core
  private lazy var windowSwitcherWindow = WindowSwitcherWindow(commandRunner: core.commandRunner)

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

  func openPrompt<Content>(_ content: () -> Content) where Content: View {
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

        var payload = payload
        if case .systemCommand(let kind) = payload {
          payload = switch kind {
          case .activateLastApplication: .systemCommand(kind: .activateLastApplication)
          case .applicationWindows: .systemCommand(kind: .applicationWindows)
          case .minimizeAllOpenWindows: .systemCommand(kind: .minimizeAllOpenWindows)
          case .hideAllApps: .systemCommand(kind: .hideAllApps)
          case .missionControl: .systemCommand(kind: .missionControl)
          case .moveFocusToNextWindowOnLeft: .windowFocus(kind: .moveFocusToNextWindowOnLeft)
          case .moveFocusToNextWindowOnRight: .windowFocus(kind: .moveFocusToNextWindowOnRight)
          case .moveFocusToNextWindowUpwards: .windowFocus(kind: .moveFocusToNextWindowUpwards)
          case .moveFocusToNextWindowDownwards: .windowFocus(kind: .moveFocusToNextWindowDownwards)
          case .moveFocusToNextWindowUpperLeftQuarter:  .windowFocus(kind: .moveFocusToNextWindowUpperLeftQuarter)
          case .moveFocusToNextWindowUpperRightQuarter: .windowFocus(kind: .moveFocusToNextWindowUpperRightQuarter)
          case .moveFocusToNextWindowLowerLeftQuarter:  .windowFocus(kind: .moveFocusToNextWindowLowerLeftQuarter)
          case .moveFocusToNextWindowLowerRightQuarter: .windowFocus(kind: .moveFocusToNextWindowLowerRightQuarter)
          case .moveFocusToNextWindowCenter: .windowFocus(kind: .moveFocusToNextWindowCenter)
          case .moveFocusToNextWindowFront: .windowFocus(kind: .moveFocusToNextWindowFront)
          case .moveFocusToPreviousWindowFront: .windowFocus(kind: .moveFocusToPreviousWindowFront)
          case .moveFocusToNextWindow: .windowFocus(kind: .moveFocusToNextWindow)
          case .moveFocusToPreviousWindow: .windowFocus(kind: .moveFocusToPreviousWindow)
          case .moveFocusToNextWindowGlobal: .windowFocus(kind: .moveFocusToNextWindowGlobal)
          case .moveFocusToPreviousWindowGlobal: .windowFocus(kind: .moveFocusToPreviousWindowGlobal)
          case .showDesktop: .systemCommand(kind: .showDesktop)

          case .windowTilingLeft: .windowTiling(kind: .left)
          case .windowTilingRight: .windowTiling(kind: .right)

          case .windowTilingTop: .windowTiling(kind: .top)
          case .windowTilingBottom: .windowTiling(kind: .bottom)
          case .windowTilingTopLeft: .windowTiling(kind: .topLeft)
          case .windowTilingTopRight: .windowTiling(kind: .topRight)
          case .windowTilingBottomLeft: .windowTiling(kind: .bottomLeft)
          case .windowTilingBottomRight: .windowTiling(kind: .bottomRight)
          case .windowTilingCenter: .windowTiling(kind: .center)
          case .windowTilingFill: .windowTiling(kind: .fill)
          case .windowTilingZoom: .windowTiling(kind: .zoom)
          case .windowTilingArrangeLeftRight: .windowTiling(kind: .arrangeLeftRight)
          case .windowTilingArrangeRightLeft: .windowTiling(kind: .arrangeRightLeft)
          case .windowTilingArrangeTopBottom: .windowTiling(kind: .arrangeTopBottom)
          case .windowTilingArrangeBottomTop: .windowTiling(kind: .arrangeBottomTop)
          case .windowTilingArrangeLeftQuarters: .windowTiling(kind: .arrangeLeftQuarters)
          case .windowTilingArrangeRightQuarters: .windowTiling(kind: .arrangeRightQuarters)
          case .windowTilingArrangeTopQuarters: .windowTiling(kind: .arrangeTopQuarters)
          case .windowTilingArrangeBottomQuarters: .windowTiling(kind: .arrangeBottomQuarters)
          case .windowTilingArrangeDynamicQuarters: .windowTiling(kind: .arrangeDynamicQuarters)
          case .windowTilingArrangeQuarters: .windowTiling(kind: .arrangeQuarters)
          case .windowTilingPreviousSize: .windowTiling(kind: .previousSize)
          }
        }

        updater.modifyWorkflow(using: transaction) { workflow in
          let resolvedCommandId: String = commandId ?? UUID().uuidString
          var command: Command
          switch payload {
          case .placeholder:
            return
          case .builtIn(let newCommand):
            command = .builtIn(newCommand)
          case .bundled(let newCommand):
            workflow.execution = .serial
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
                            let inBackground, let hideWhenRunning, let ifNotRunning, let waitForAppToLaunch, let addToStage):
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
            command = Command.systemCommand(.init(id: resolvedCommandId,
                                                  name: "System command",
                                                  kind: kind,
                                                  notification: nil))
          case .uiElement(let predicates):
            command = Command.uiElement(.init(meta: Command.MetaData(id: resolvedCommandId), predicates: predicates))
          case .windowFocus(let kind):
            command = Command.windowFocus(.init(kind: kind, meta: Command.MetaData(id: resolvedCommandId)))
          case .windowManagement(let kind):
            command = Command.windowManagement(.init(id: resolvedCommandId,
                                                     name: "Window Management Command",
                                                     kind: kind,
                                                     notification: nil,
                                                     animationDuration: 0))
          case .windowTiling(let kind):
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
