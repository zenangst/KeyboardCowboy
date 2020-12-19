import SwiftUI
import ModelKit

public struct CommandListView: View {
  public enum Action {
    case create(Command, in: Workflow)
    case edit(Command, in: Workflow)
    case move(Command, offset: Int, in: Workflow)
    case delete(Command, in: Workflow)
    case reveal(Command)
    case run(Command)
    case drop([URL], Workflow)
  }

  public enum Sheet: Identifiable {
    case create(Command)
    case edit(Command)

    public var id: String { return UUID().uuidString }
  }

  @Environment(\.colorScheme) var colorScheme
  @Binding var selection: Command?
  @Binding var workflow: Workflow
  let perform: (Action) -> Void
  let receive: (Sheet) -> Void

  public var body: some View {
    VStack {
      if !workflow.commands.isEmpty {
        list
      } else {
        addButton
      }
    }
  }
}

// MARK: Extentions

extension CommandListView {
  var list: some View {
    ForEach(workflow.commands) { command in
      MovableStack(
        element: command,
        dragHandler: { offset, command in
          let indexOffset = round(offset.height / 48)
          perform(.move(command, offset: Int(indexOffset), in: workflow))
        }, content: { item(command) })
    }
    .animation(.linear)
  }

  func item(_ command: Command) -> some View {
      HStack(spacing: 12) {
        CommandView(
          command: command,
          editAction: { receive(.edit($0)) },
          revealAction: { perform(.reveal($0)) },
          runAction: { perform(.run($0)) },
          showContextualMenu: true)
          .padding(.horizontal, 8)
        Spacer()
        Text("≣")
          .font(.title)
          .foregroundColor(Color(.secondaryLabelColor))
          .padding(16)
          .offset(x: 0, y: -2)
          .cursorOnHover(.closedHand)
      }
      .frame(height: 48)
      .background(LinearGradient(
                    gradient: Gradient(
                      stops:
                        colorScheme == .dark
                        ? [.init(color: Color(.gridColor).opacity(0.25), location: 0.33),
                           .init(color: Color(.gridColor).opacity(0.4), location: 1.0)]
                        : [.init(color: Color(.textBackgroundColor).opacity(1), location: 0.0),
                           .init(color: Color(.textBackgroundColor).opacity(0.75), location: 1.0)]
                    ),
                    startPoint: .top,
                    endPoint: .bottom))
      .cornerRadius(8)
      .onTapGesture {
        if let tableView = NSApp.keyWindow?.firstResponder as? NSTableView {
          tableView.isEnabled = false
          tableView.resignFirstResponder()
          tableView.isEnabled = true
        }
        selection = command
      }
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(selection == command
                    ? Color(.controlAccentColor)
                    : Color(.windowFrameTextColor),
                  lineWidth: 1)
          .opacity(selection == command ? 1.0 : 0.05)
      )
      .padding(.horizontal)
      .shadow(color: Color(.shadowColor).opacity(0.05), radius: 10, x: 0, y: 12.5)
      .animation(.none)
      .contextMenu {
        CommandListContextMenu(editAction: { receive(.edit(command)) },
                               deleteAction: { perform(.delete(command, in: workflow)) })
      }
  }

  var addButton: some View {
    AddButton(text: "Add Command",
              alignment: .center,
              action: {
                receive(.create(Command.empty(.application)))
              }).padding(.vertical, 8)
  }
}

// MARK: Previews

struct CommandListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    CommandListView(selection: .constant(nil),
                    workflow: .constant(ModelFactory().workflowDetail()),
                    perform: { _ in },
                    receive: { _ in })
  }
}
