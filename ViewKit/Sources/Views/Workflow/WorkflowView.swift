import SwiftUI

struct WorkflowView: View {
  static let idealWidth: CGFloat = 500

  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var commandController: CommandController
  @ObservedObject var openPanelController: OpenPanelController
  @State private var newCommandVisible: Bool = false
  @Binding var workflow: WorkflowViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack {
        name.padding(.horizontal)
      }
      .padding(.top, 32)
      .padding(.bottom, 16)

      if keyboardShortcutController.state.isEmpty {
        addKeyboardShortcut.padding(.vertical, 8)
      } else {
        VStack(alignment: .leading) {
          HeaderView(title: "Keyboard shortcuts:")
          keyboardShortcuts.frame(
            height: max(min(45 * CGFloat(keyboardShortcutController.state.count), 176), 45)
          )
        }
        .padding(.top, 12)
      }

      Divider()
        .padding(16)

      VStack(alignment: .leading) {
        HeaderView(title: "Commands:")
        commands
      }

      addCommandButton.padding(8)
    }
    .background(LinearGradient(
                  gradient:
                    Gradient(colors: [Color(.windowBackgroundColor).opacity(0.5),
                                      Color(.gridColor).opacity(0.5)]),
                  startPoint: .top,
                  endPoint: .bottom))
  }
}

private extension WorkflowView {
  var name: some View {
    TextField("", text: $workflow.name)
      .font(.largeTitle)
      .foregroundColor(.primary)
      .textFieldStyle(PlainTextFieldStyle())
  }

  var keyboardShortcuts: some View {
    KeyboardShortcutListView(keyboardShortcuts: workflow.keyboardShortcuts)
      .background(Color(.windowBackgroundColor))
      .cornerRadius(8.0)
      .padding(.horizontal, 16)
      .frame(alignment: .top)
      .listStyle(DefaultListStyle())
      .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 3)
  }

  var addKeyboardShortcut: some View {
    HStack {
      RoundOutlinedButton(title: "+", color: Color(.secondaryLabelColor))
        .onTapGesture {
          keyboardShortcutController.perform(.createKeyboardShortcut(KeyboardShortcutViewModel.empty(),
                                                                     index: keyboardShortcutController.state.count))
        }
      Button("Add Keyboard Shortcut", action: {
        keyboardShortcutController.perform(.createKeyboardShortcut(KeyboardShortcutViewModel.empty(),
                                                                   index: keyboardShortcutController.state.count))
      })
      .buttonStyle(PlainButtonStyle())
    }.padding(8)
  }

  var commands: some View {
    CommandListView(applicationProvider: applicationProvider,
                    commandController: commandController,
                    openPanelController: openPanelController)
      .cornerRadius(8.0)
      .frame(alignment: .top)
      .padding(.horizontal, 16)
      .padding(.bottom, 24)
      .shadow(color: Color(.controlDarkShadowColor).opacity(0.05), radius: 5, x: 0, y: 2.5)
  }

  var addCommandButton: some View {
    HStack(spacing: 4) {
      RoundOutlinedButton(title: "+", color: Color(.secondaryLabelColor))
        .onTapGesture {
          newCommandVisible = true
        }
      Button("Add Command", action: {
        newCommandVisible = true
      })
      .buttonStyle(PlainButtonStyle())
    }
    .sheet(isPresented: $newCommandVisible, content: {
      EditCommandView(
        applicationProvider: applicationProvider,
        openPanelController: openPanelController,
        saveAction: { newCommand in
          commandController.action(.createCommand(newCommand))()
          newCommandVisible = false
      },
      cancelAction: {
        newCommandVisible = false
      },
        selection: CommandViewModel.Kind.application(ApplicationViewModel.empty()),
        commandViewModel: CommandViewModel(id: "", name: "", kind: .application(ApplicationViewModel.empty())))
    })
  }
}

// MARK: - Previews

struct WorkflowView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowView(applicationProvider: ApplicationPreviewProvider().erase(),
                 commandController: CommandPreviewController().erase(),
                 openPanelController: OpenPanelPreviewController().erase(),
                 workflow: .constant(ModelFactory().workflowDetail()))
      .frame(height: 668)
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
