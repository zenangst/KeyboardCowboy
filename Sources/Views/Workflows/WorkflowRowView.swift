import SwiftUI

struct WorkflowRowView: View, Equatable {
  let applicationStore: ApplicationStore
  @Binding var workflow: Workflow

  var body: some View {
    HStack {
      icons(workflow.commands)
        .frame(width: 32, height: 32)
      Text(workflow.name)
        .lineLimit(1)
        .allowsTightening(true)
      Spacer()
      if let trigger = workflow.trigger {
        triggers(trigger)
          .font(.caption)
      }
    }
    .padding(4)
    .opacity(workflow.isEnabled ? 1.0 : 0.6)
    .if(workflow.commands.count > 1, transform: { $0.badge(workflow.commands.count) })
  }

  @ViewBuilder
  func triggers(_ trigger: Workflow.Trigger) -> some View {
    switch trigger {
    case .keyboardShortcuts(let shortcuts):
      HStack {
        if shortcuts.count > 3 {
          ForEach(shortcuts[0..<3], content: KeyboardShortcutView.init)
          if shortcuts.count > 3 {
            KeyboardShortcutView(shortcut: .init(key: "..."))
          }
        } else {
          ForEach(shortcuts, content: KeyboardShortcutView.init)
        }
      }
    case .application(let triggers):
      ZStack {
        ForEach(triggers) { contextView($0.contexts) }
      }
    }
  }

  @ViewBuilder
  func contextView(_ contexts: Set<ApplicationTrigger.Context>) -> some View {
    VStack(spacing: 1) {
      Circle().fill( contexts.contains(.closed) ?  Color(.systemRed) : Color.clear)
        .frame(width: 3, height: 3)
      Circle().fill( contexts.contains(.launched) ?  Color(.systemYellow) : Color.clear)
        .frame(width: 3, height: 3)
      Circle().fill( contexts.contains(.frontMost) ?  Color(.systemGreen) : Color.clear)
        .frame(width: 3, height: 3)
    }
    .padding(1)
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(Color(NSColor.systemGray.withSystemEffect(.disabled)), lineWidth: 1)
    )
    .opacity(0.8)
  }

  func icons(_ commands: [Command]) -> some View {
    ZStack {
      if commands.count > 3 {
        ForEach(commands[0..<3], content: commandView)
      } else {
        ForEach(commands, content: commandView)
      }
    }
  }

  @ViewBuilder
  func commandView(_ command: Command) -> some View {
    switch command {
    case .application(let command):
      IconView(path: command.application.path)
        .frame(width: 32, height: 32)
        .id(command.application.id)
    case .script(let command):
      switch command {
      case .appleScript:
        IconView(path: "/System/Applications/Utilities/Script Editor.app")
          .frame(width: 32, height: 32)
      case .shell:
        IconView(path: "/System/Applications/Utilities/Terminal.app")
          .frame(width: 32, height: 32)
      }
    case .keyboard(let command):
      RegularKeyIcon(letter: command.keyboardShortcut.key, width: 32, height: 32)
        .frame(width: 24, height: 24)
    case .open(let command):
      if let application = command.application {
        IconView(path: application.path)
          .frame(width: 32, height: 32)
          .id(application.id)
      } else if command.isUrl {
        IconView(path: "/Applications/Safari.app")
          .frame(width: 32, height: 32)
      } else {
        IconView(path: command.path)
          .frame(width: 32, height: 32)
      }
      Spacer()
    case .builtIn:
      Spacer()
    case .type:
      Spacer()
    }
  }

  static func == (lhs: WorkflowRowView, rhs: WorkflowRowView) -> Bool {
    lhs.workflow.id == rhs.workflow.id &&
    lhs.workflow.isEnabled == rhs.workflow.isEnabled &&
    lhs.workflow.name == rhs.workflow.name &&
    lhs.workflow.trigger == rhs.workflow.trigger &&
    lhs.workflow.commands == rhs.workflow.commands
  }
}

struct WorkflowRowView_Previews: PreviewProvider {
    static var previews: some View {
      WorkflowRowView(
        applicationStore: ApplicationStore(),
        workflow: .constant(Workflow.designTime(.none)))
    }
}
