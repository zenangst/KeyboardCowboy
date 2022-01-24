import Apps
import SwiftUI

struct WorkflowListView: View {
  var workflows: [Workflow]
  @Binding var selection: Set<String>

  var body: some View {
    List(workflows, selection: $selection) { workflow in
      HStack {
        VStack(alignment: .leading, spacing: 0) {
          Text(workflow.name)
          HStack {
            Text("\(workflow.commands.count) command") + Text(workflow.commands.count > 1 ? "s" : "")
            Divider().frame(height: 10)
            triggers(workflow.trigger)
          }
          .font(Font.caption)
          .foregroundColor(Color(.secondaryLabelColor))
        }
        Spacer()
        icons(workflow.commands)
      }
      .padding(4)
      .opacity(workflow.isEnabled ? 1.0 : 0.6)
      .id(workflow.id)
    }.listStyle(InsetListStyle())
  }

  @ViewBuilder
  func triggers(_ trigger: Workflow.Trigger?) -> some View {
    switch trigger {
    case .keyboardShortcuts(let shortcuts):
      ForEach(shortcuts, content: KeyboardShortcutView.init)
    case .application(let applicationTriggers):
      ApplicationTriggerListView(applicationTriggers: applicationTriggers)
    case .none:
      Spacer()
    }
  }

  func icons(_ commands: [Command]) -> some View {
    ZStack {
      ForEach(commands, id: \.self) { command in
        switch command {
        case .application(let command):
          IconView(path: command.application.path)
            .frame(width: 32, height: 32)
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
          RegularKeyIcon(letter: command.keyboardShortcut.key)
            .frame(width: 24, height: 24)
            .offset(x: -4, y: 0)
        case .open(let command):
          if let application = command.application {
            IconView(path: application.path)
              .frame(width: 32, height: 32)
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
    }
  }
}

struct WorkflowListView_Previews: PreviewProvider {
  static let store = Saloon()
  static var previews: some View {
    WorkflowListView(
      workflows: Array(store.selectedGroups.flatMap({ $0.workflows })),
      selection: .constant([]))
      .previewLayout(.sizeThatFits)
  }
}
