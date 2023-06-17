import Apps
import Carbon
import SwiftUI

struct NewCommandWindow: Scene {
  enum Context: Identifiable, Hashable, Codable {
    var id: String {
      switch self {
      case .newCommand(let workflowId):
        return workflowId
      case .editCommand(let workflowId, let commandId):
        return workflowId + commandId
      }
    }

    case newCommand(workflowId: Workflow.ID)
    case editCommand(workflowId: Workflow.ID, commandId: Command.ID)
  }

  private let onSave: (_ workflowId: Workflow.ID,
                       _ commandId: Command.ID?,
                       _ title: String,
                       _ payload: NewCommandPayload) -> Void
  private let contentStore: ContentStore
  private let defaultSelection: NewCommandView.Kind = .application
  private let defaultPayload: NewCommandPayload = .application(
    application: nil,
    action: .open,
    inBackground: false,
    hideWhenRunning: false,
    ifNotRunning: false)

  init(contentStore: ContentStore,
       onSave: @escaping (_ workflowId: Workflow.ID, _ commandId: Command.ID?, _ title: String, _ payload: NewCommandPayload) -> Void) {
    self.contentStore = contentStore
    self.onSave = onSave
  }

  var body: some Scene {
    WindowGroup(for: Context.self) { $context in
      Group {
        switch context {
        case .editCommand(let workflowId, let commandId):
          if let command = contentStore.groupStore.command(withId: commandId, workflowId: workflowId) {
            contentView(workflowId,
                        title: command.name,
                        selection: selection(for: command),
                        payload: payload(for: command),
                        commandId: commandId)
          } else {
            contentView(workflowId, title: "Untitled command", selection: defaultSelection,
                        payload: defaultPayload, commandId: nil)
          }
        case .newCommand(let workflowId):
          contentView(workflowId, title: "Untitled command", selection: defaultSelection,
                      payload: defaultPayload, commandId: nil)
        case .none:
          EmptyView()
        }
      }
      // MARK: Note - Force dark mode until the light theme is up-to-date
      .environment(\.colorScheme, .dark)
    }
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.topTrailing)
  }

  @MainActor
  private func contentView(_ workflowId: Workflow.ID,
                           title: String,
                           selection: NewCommandView.Kind,
                           payload: NewCommandPayload,
                           commandId: Command.ID?) -> some View {
    NewCommandView(
      workflowId: workflowId,
      commandId: commandId,
      title: title,
      selection: selection,
      payload: payload,
      onDismiss: {
        closeWindow()
      }, onSave: { payload, title in
        onSave(workflowId, commandId, title, payload)
        closeWindow()
      })
    .environmentObject(contentStore.recorderStore)
    .environmentObject(contentStore.shortcutStore)
    .environmentObject(contentStore.applicationStore)
    .environmentObject(OpenPanelController())
    .ignoresSafeArea(edges: .all)
  }

  private func payload(for command: Command) -> NewCommandPayload {
    switch command {
    case .application(let applicationCommand):
      let action: NewCommandApplicationView.ApplicationAction
      switch applicationCommand.action {
      case .open:
        action = .open
      case .close:
        action = .close
      }

      let inBackground = applicationCommand.modifiers.contains(.background)
      let hideWhenRunning = applicationCommand.modifiers.contains(.hidden)
      let ifNotRunning = applicationCommand.modifiers.contains(.onlyIfNotRunning)

      return .application(application: applicationCommand.application,
                          action: action,
                          inBackground: inBackground,
                          hideWhenRunning: hideWhenRunning,
                          ifNotRunning: ifNotRunning)
    case .builtIn:
      return .placeholder
    case .menuBar(let command):
      return .menuBar(tokens: command.tokens)
    case .keyboard:
      return .placeholder
    case .open(let openCommand):
      return .open(path: openCommand.path, application: openCommand.application)
    case .shortcut(let shortcutCommand):
      return .shortcut(name: shortcutCommand.name)
    case .script(let scriptCommand):
      let source: String
      let kind: NewCommandScriptView.Kind
      let scriptExtension: NewCommandScriptView.ScriptExtension

      switch (scriptCommand.kind, scriptCommand.source) {
      case (.appleScript, .inline(let newSource)):
        source = newSource
        kind = .source
        scriptExtension = .appleScript
      case (.appleScript, .path(let path)):
        source = path
        kind = .file
        scriptExtension = .appleScript
      case (.shellScript, .inline(let newSource)):
        source = newSource
        kind = .source
        scriptExtension = .shellScript
      case (.shellScript, .path(let path)):
        source = path
        kind = .file
        scriptExtension = .shellScript
      }

      return .script(value: source, kind: kind, scriptExtension: scriptExtension)
    case .type(let typeCommand):
      return .type(text: typeCommand.input)
    case .systemCommand(let systemCommand):
      return .systemCommand(kind: systemCommand.kind)
    }
  }

  private func selection(for command: Command) -> NewCommandView.Kind {
    switch command {
    case .application:
      return .application
    case .builtIn:
      // TODO: Fix this!
      return .application
    case .keyboard:
      return .keyboardShortcut
    case .menuBar:
      return .menuBar
    case .open:
      return .open
    case .shortcut:
      return .shortcut
    case .script:
      return .script
    case .type:
      return .type
    case .systemCommand:
      return .system
    }
  }

  private func closeWindow() {
    KeyboardCowboy.keyWindow?.close()
    KeyboardCowboy.mainWindow?.makeKey()
  }
}

