import SwiftUI
import ModelKit

struct WorkflowView: View {
  static let idealWidth: CGFloat = 500

  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var commandController: CommandController
  @ObservedObject var keyboardShortcutController: KeyboardShortcutController
  @ObservedObject var openPanelController: OpenPanelController
  @State private var newCommandVisible: Bool = false
  @Binding var workflow: Workflow

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack {
        name.padding(.horizontal)
      }
      .padding(.bottom, 16)

      if keyboardShortcutController.state.isEmpty {
        addKeyboardShortcut.padding(.vertical, 8)
      } else {
        VStack(alignment: .leading) {
          HeaderView(title: "Keyboard shortcuts:").padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
          keyboardShortcuts.frame(
            height: max(min(72 * CGFloat(keyboardShortcutController.state.count), 176), 72)
          )
        }
        .padding(.top, 12)
      }

      Divider()
        .padding(16)

      VStack(alignment: .leading) {
        HeaderView(title: "Commands:").padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
        commands
      }

      addCommandButton.padding(8)
    }
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
    KeyboardShortcutListView(keyboardShortcutController: keyboardShortcutController)
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
          keyboardShortcutController.perform(.createKeyboardShortcut(
                                              keyboardShortcut: ModelKit.KeyboardShortcut.empty(),
                                              index: keyboardShortcutController.state.count))
        }
      Button("Add Keyboard Shortcut", action: {
        keyboardShortcutController.perform(.createKeyboardShortcut(
                                            keyboardShortcut: ModelKit.KeyboardShortcut.empty(),
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
        selection: Command.application(.init(application: Application.empty())),
        command: Command.application(.init(application: Application.empty())))
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
                 keyboardShortcutController: KeyboardShortcutPreviewController().erase(),
                 openPanelController: OpenPanelPreviewController().erase(),
                 workflow: .constant(ModelFactory().workflowDetail()))
      .frame(height: 668)
  }
}
