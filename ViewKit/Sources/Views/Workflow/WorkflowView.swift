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
  @Environment(\.colorScheme) var colorScheme
  @State private var newCommandVisible: Bool = false
  @State var isDropping: Bool = false

  public var body: some View {
    ScrollView {
      VStack {
        VStack {
          name(workflow, in: group)
        }
        .padding([.horizontal, .top])
        .background(Color(.textBackgroundColor))
        Divider()
        VStack(alignment: .leading, spacing: 0) {
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
              .padding([.leading, .top])
            keyboardShortcuts(for: workflow)
              .padding(.top)
              .cornerRadius(8.0)
          }
        }.padding(.horizontal, 8)
      }
      .background(Color(.textBackgroundColor))

      VStack(alignment: .leading, spacing: 0) {
        HeaderView(title: "Commands:")
          .padding([.leading, .top])
        if workflow.commands.isEmpty {
          VStack {
            AddButton(text: "Add Command",
                      alignment: .center,
                      action: { newCommandVisible = true }).padding(.vertical, 8)
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
        } else {
          commands(for: workflow).padding(.top)
        }
      }
      .onDrop($isDropping) {
        workflowController.perform(.drop($0, workflow, in: group))
      }
      .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.accentColor, lineWidth: isDropping ? 5 : 0)
            .padding(4)
      )
      .frame(alignment: .leading)
      .padding(.horizontal, 8)
    }
    .background(LinearGradient(
                  gradient: Gradient(
                    stops: [
                      .init(color: Color(.windowBackgroundColor).opacity(0.25), location: 0.8),
                      .init(color: Color(.gridColor).opacity(0.75), location: 1.0),
                    ]),
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
    KeyboardShortcutList(keyboardShortcutController: keyboardShortcutController,
                             keyboardShortcuts: workflow.keyboardShortcuts,
                             workflow: workflow)
      .background(Color(.windowBackgroundColor))
      .frame(alignment: .top)
      .cornerRadius(8)
      .padding([.bottom, .leading, .trailing], 16)
      .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color(.windowFrameTextColor),
                    lineWidth: 1)
            .opacity(0.05)
            .padding([.bottom, .leading, .trailing], 16)
      )
      .shadow(color: Color(.separatorColor).opacity(0.05), radius: 5, x: 0, y: 2.5)
  }

  func commands(for workflow: Workflow) -> some View {
    CommandListView(applicationProvider: applicationProvider,
                    commandController: commandController,
                    openPanelController: openPanelController,
                    workflow: workflow)
      .frame(alignment: .top)
      .padding(.bottom, 24)
      .shadow(color: Color(.separatorColor).opacity(0.05), radius: 5, x: 0, y: 2.5)
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
