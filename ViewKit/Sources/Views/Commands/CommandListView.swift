import SwiftUI

public struct CommandListView: View {
  public enum Action {
    case createCommand(CommandViewModel)
    case updateCommand(CommandViewModel)
    case deleteCommand(CommandViewModel)
    case runCommand(CommandViewModel)
    case revealCommand(CommandViewModel)
    case moveCommand(from: Int, to: Int)
  }

  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var commandController: CommandController
  @ObservedObject var openPanelController: OpenPanelController
  @State private var selection: CommandViewModel?
  @State private var editCommand: CommandViewModel?

  public var body: some View {
    List {
      ForEach(commandController.state) { command in
        HStack(spacing: 12) {
          CommandView(command: command,
                      editAction: { viewModel in
                        editCommand = viewModel
                      },
                      revealAction: { command in
                        commandController.action(.revealCommand(command))()
                      },
                      runAction: { command in
                        commandController.action(.runCommand(command))()
                      },
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
    .sheet(item: $editCommand, content: { viewModel in
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
        selection: viewModel.kind,
        commandViewModel: viewModel)
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

private final class ApplicationPreviewProvider: StateController {
  let state = [ApplicationViewModel]()
}

private final class CommandPreviewController: ViewController {
  let state = ModelFactory().workflowDetail().commands
  func perform(_ action: CommandListView.Action) {}
}

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}
