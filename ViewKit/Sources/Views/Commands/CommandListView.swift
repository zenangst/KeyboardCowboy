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

  @ObservedObject var applicationProvider: ApplicationProvider
  var commandController: CommandController
  @ObservedObject var openPanelController: OpenPanelController
  @State private var selection: Command?
  @State private var editCommand: Command?

  let workflow: Workflow

  public var body: some View {
    VStack(alignment: .leading) {
      ForEach(workflow.commands) { command in
        MovableView(
          element: command,
          dragHandler: { offset, command in
            let indexOffset = round(offset.height / 48)
            commandController.perform(.moveCommand(command, offset: Int(indexOffset), in: workflow))
          }, {
            HStack(spacing: 12) {
              CommandView(
                command: command,
                editAction: { editCommand = $0 },
                revealAction: { commandController.action(.revealCommand($0, in: workflow))() },
                runAction: { commandController.action(.runCommand($0))() },
                showContextualMenu: true)
                .contextMenu(menuItems: {
                  Button("Edit", action: {
                    editCommand = command
                  })
                })
                .padding(.horizontal, 8)
              Spacer()
              Text("≣")
                .font(.title)
                .foregroundColor(Color(.secondaryLabelColor))
                .padding(16)
                .offset(x: 0, y: -2)
            }
            .frame(height: 48, alignment: .center)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
            .animation(.none)
            .contextMenu {
              Button("Edit") { editCommand = command }
              Divider()
              Button("Delete") { commandController.perform(.deleteCommand(command, in: workflow)) }
            }
          })
      }
      .animation(.linear)
      .sheet(item: $editCommand, content: { model in
        EditCommandView(
          applicationProvider: applicationProvider,
          openPanelController: openPanelController,
          saveAction: { newCommand in
            commandController.action(.updateCommand(newCommand, in: workflow))()
            editCommand = nil
          },
          cancelAction: {
            editCommand = nil
          },
          selection: model,
          command: model)
      })
    }
  }
}

// MARK: - Previews

struct CommandListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    CommandListView(applicationProvider: ApplicationPreviewProvider().erase(),
                    commandController: CommandPreviewController().erase(),
                    openPanelController: OpenPanelPreviewController().erase(),
                    workflow: ModelFactory().workflowDetail())
  }
}
