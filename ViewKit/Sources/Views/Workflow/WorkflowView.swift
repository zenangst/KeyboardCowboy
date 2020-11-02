import SwiftUI
import ModelKit

public struct WorkflowView: View {
  static let idealWidth: CGFloat = 500

  let workflow: Workflow
  let group: ModelKit.Group
  let applicationProvider: ApplicationProvider
  let commandController: CommandController
  let keyboardShortcutController: KeyboardShortcutController
  let openPanelController: OpenPanelController
  let workflowController: WorkflowController
  @State private var newCommandVisible: Bool = false

  public var body: some View {
    VStack(alignment: .leading) {
      ScrollView {
        name(workflow, in: group).padding(.horizontal)

        VStack(alignment: .leading) {
          if workflow.keyboardShortcuts.isEmpty {
            VStack {
              AddButton(text: "Add Keyboard Shortcut",
                        alignment: .center,
                        action: {
                keyboardShortcutController.perform(.createKeyboardShortcut(
                                                    ModelKit.KeyboardShortcut.empty(),
                                                    index: workflow.keyboardShortcuts.count,
                                                    in: workflow))
              }).padding(.vertical, 8)
            }
          } else {
            HeaderView(title: "Keyboard shortcuts:")
              .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
            keyboardShortcuts(for: workflow)
          }
        }

        Divider().padding(16)

        VStack(alignment: .leading) {
          HeaderView(title: "Commands:")
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
          commands(for: workflow)
        }
      }
      addCommandButton
    }.background(LinearGradient(
                  gradient: Gradient(colors: [Color(.clear), Color(.gridColor).opacity(0.5)]),
                  startPoint: .top,
                  endPoint: .bottom))
  }
}

private extension WorkflowView {
  func name(_ workflow: Workflow, in group: ModelKit.Group) -> some View {
    TextField("", text: Binding<String>(get: { workflow.name }, set: { name in
      var workflow = workflow
      workflow.name = name
      workflowController.action(.updateWorkflow(workflow, in: group))()
    }))
      .font(.largeTitle)
      .foregroundColor(.primary)
      .textFieldStyle(PlainTextFieldStyle())
  }

  func keyboardShortcuts(for workflow: Workflow) -> some View {
    KeyboardShortcutListView(keyboardShortcutController: keyboardShortcutController,
                             keyboardShortcuts: workflow.keyboardShortcuts,
                             workflow: workflow)
      .frame(alignment: .top)
      .padding(.bottom, 24)
      .shadow(color: Color(.controlDarkShadowColor).opacity(0.05), radius: 5, x: 0, y: 2.5)
  }

  func commands(for workflow: Workflow) -> some View {
    CommandListView(applicationProvider: applicationProvider,
                    commandController: commandController,
                    openPanelController: openPanelController,
                    workflow: workflow)
      .frame(alignment: .top)
      .padding(.bottom, 24)
      .shadow(color: Color(.controlDarkShadowColor).opacity(0.05), radius: 5, x: 0, y: 2.5)
  }

  var addCommandButton: some View {
    AddButton(text: "Add Command",
              alignment: .left,
              action: { newCommandVisible = true })
    .sheet(isPresented: $newCommandVisible, content: {
      EditCommandView(
        applicationProvider: applicationProvider,
        openPanelController: openPanelController,
        saveAction: { newCommand in
          commandController.action(.createCommand(newCommand, in: workflow))()
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
    DesignTimeFactory().workflowDetail(
      ModelFactory().workflowDetail(),
      group: ModelFactory().groupList().first!)
      .environmentObject(UserSelection())
      .frame(height: 668)
  }
}
