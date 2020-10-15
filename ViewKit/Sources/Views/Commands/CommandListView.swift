import SwiftUI
import ModelKit

public struct CommandListView: View {
  public enum Action {
    case createCommand(Command)
    case updateCommand(Command)
    case deleteCommand(Command)
    case runCommand(Command)
    case revealCommand(Command)
    case moveCommand(from: Int, to: Int)
  }

  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var commandController: CommandController
  @ObservedObject var openPanelController: OpenPanelController
  @State private var selection: Command?
  @State private var editCommand: Command?

  public var body: some View {
    List {
      ForEach(commandController.state) { command in
        HStack(spacing: 12) {
          CommandView(
            command: command,
            editAction: { editCommand = $0 },
            revealAction: { commandController.action(.revealCommand($0))() },
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
            .padding(8)
            .offset(x: 0, y: -2)
        }
        .frame(height: 48, alignment: .center)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
        .tag(command)
        .onTapGesture(count: 2, perform: {
          editCommand = command
        })
        .contextMenu {
          Button("Edit") { editCommand = command }
          Divider()
          Button("Delete") { commandController.perform(.deleteCommand(command)) }
        }
      }
      .onMove(perform: { indices, newOffset in
        for i in indices {
          commandController.perform(.moveCommand(from: i, to: newOffset))
        }
      }).onDelete(perform: { indexSet in
        for index in indexSet {
          let command = commandController.state[index]
          commandController.perform(.deleteCommand(command))
        }
      })
    }
    .padding(.horizontal, -18)
    .sheet(item: $editCommand, content: { model in
      EditCommandView(
        applicationProvider: applicationProvider,
        openPanelController: openPanelController,
        saveAction: { newCommand in
          commandController.action(.updateCommand(newCommand))()
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

// MARK: - Previews

struct CommandListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    CommandListView(applicationProvider: ApplicationPreviewProvider().erase(),
                    commandController: CommandPreviewController().erase(),
                    openPanelController: OpenPanelPreviewController().erase())
  }
}
