import SwiftUI
import ModelKit

public struct CommandListView: View {
  public enum Action {
    case createCommand(Command, in: Workflow)
    case updateCommand(Command, in: Workflow)
    case deleteCommand(Command, in: Workflow)
    case runCommand(Command)
    case revealCommand(Command, in: Workflow)
    case moveCommand(Command, offset: Int, in: Workflow)
  }

  public enum UIAction {
    case edit(Command)
    case move(Command, Int)
    case reveal(Command)
    case run(Command)
    case delete(Command)
  }

  @Environment(\.colorScheme) var colorScheme
  @State private var selection: Command?
  @Binding var workflow: Workflow

  let performAction: (UIAction) -> Void

  public var body: some View {
    VStack {
      ForEach(workflow.commands) { command in
        MovableView(
          element: command,
          dragHandler: { offset, command in
            let indexOffset = round(offset.height / 48)
            performAction(.move(command, Int(indexOffset)))
          }, {
            HStack(spacing: 12) {
              CommandView(
                command: command,
                editAction: { performAction(.edit($0)) },
                revealAction: { performAction(.reveal($0)) },
                runAction: { performAction(.run($0)) },
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
              Button("Edit") { performAction(.edit(command)) }
              Divider()
              Button("Delete") { performAction(.delete(command)) }
            }
          })
      }.animation(.linear)
    }
  }
}

// MARK: - Previews

struct CommandListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    CommandListView(workflow: .constant(ModelFactory().workflowDetail())) { _ in }
  }
}
