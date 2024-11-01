import AppKit
import Bonzai
import SwiftUI

@MainActor
final class NewCommandWindow: NSObject, NSWindowDelegate {
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
  private var window: NSWindow?

  private let onSave: (_ workflowId: Workflow.ID,
                       _ commandId: Command.ID?,
                       _ title: String,
                       _ payload: NewCommandPayload) -> Void
  private let context: NewCommandWindow.Context
  private let configurationPublisher: ConfigurationPublisher
  private let contentStore: ContentStore
  private let uiElementCaptureStore: UIElementCaptureStore
  private let defaultSelection: NewCommandView.Kind = .application
  private let defaultPayload: NewCommandPayload = .application(
    application: nil,
    action: .open,
    inBackground: false,
    hideWhenRunning: false,
    ifNotRunning: false,
    waitForAppToLaunch: false)

  init(context: NewCommandWindow.Context,
       contentStore: ContentStore,
       uiElementCaptureStore: UIElementCaptureStore,
       configurationPublisher: ConfigurationPublisher,
       onSave: @escaping (_ workflowId: Workflow.ID, _ commandId: Command.ID?, _ title: String, _ payload: NewCommandPayload) -> Void) {
    self.context = context
    self.contentStore = contentStore
    self.configurationPublisher = configurationPublisher
    self.onSave = onSave
    self.uiElementCaptureStore = uiElementCaptureStore
  }

  func open() {
    let styleMask: NSWindow.StyleMask = [
      .closable,
      .miniaturizable,
      .resizable,
      .titled,
      .fullSizeContentView,
    ]
    let window = ZenSwiftUIWindow(styleMask: styleMask) {
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
      }
    }

    window.animationBehavior = .documentWindow

    let size = window.hostingController.sizeThatFits(in: .init(width: 320, height: 240))
    window.setFrame(NSRect(origin: .zero, size: size), display: false)
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.delegate = self
    window.makeKeyAndOrderFront(nil)
    window.center()
    self.window = window
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
        self.window?.close()
      }, onSave: { [weak self] payload, title in
        guard let self else { return }
        self.onSave(workflowId, commandId, title, payload)
        self.window?.close()
      })
    .environmentObject(contentStore.recorderStore)
    .environmentObject(contentStore.shortcutStore)
    .environmentObject(contentStore.applicationStore)
    .environmentObject(uiElementCaptureStore)
    .environmentObject(configurationPublisher)
    .environmentObject(OpenPanelController())
    .ignoresSafeArea(edges: .all)
  }

  private func payload(for command: Command) -> NewCommandPayload {
    switch command {
    case .application(let applicationCommand):
      let action: NewCommandApplicationView.ApplicationAction = switch applicationCommand.action {
      case .open:  .open
      case .close: .close
      case .hide:  .hide
      case .unhide: .unhide
      case .peek: .peek
      }

      let inBackground = applicationCommand.modifiers.contains(.background)
      let hideWhenRunning = applicationCommand.modifiers.contains(.hidden)
      let ifNotRunning = applicationCommand.modifiers.contains(.onlyIfNotRunning)
      let waitForAppToLaunch = applicationCommand.modifiers.contains(.waitForAppToLaunch)

      return .application(application: applicationCommand.application,
                          action: action,
                          inBackground: inBackground,
                          hideWhenRunning: hideWhenRunning,
                          ifNotRunning: ifNotRunning,
                          waitForAppToLaunch: waitForAppToLaunch)
    case .builtIn, .bundled:
      return .placeholder
    case .menuBar(let command):
      return .menuBar(tokens: command.tokens, application: command.application)
    case .mouse(let command):
      return .mouse(kind: command.kind)
    case .keyboard(let command):
      return .keyboardShortcut(command.keyboardShortcuts)
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
    case .text(let textCommand):
      switch textCommand.kind {
      case .insertText(let typeCommand):
        return .text(.init(.insertText(typeCommand)))
      }
    case .systemCommand(let systemCommand):
      return .systemCommand(kind: systemCommand.kind)
    case .uiElement(let model):
      return .uiElement(predicates: model.predicates)
    case .windowManagement(let windowCommand):
      return .windowManagement(kind: windowCommand.kind)
    }
  }

  private func selection(for command: Command) -> NewCommandView.Kind {
    switch command {
    case .application: .application
    case .builtIn: .builtIn
    case .bundled: .bundled
    case .keyboard: .keyboardShortcut
    case .menuBar: .menuBar
    case .mouse: .mouse
    case .open: .open
    case .shortcut: .shortcut
    case .script: .script
    case .text: .text
    case .systemCommand: .system
    case .uiElement: .uiElement
    case .windowManagement: .windowManagement
    }
  }
}
