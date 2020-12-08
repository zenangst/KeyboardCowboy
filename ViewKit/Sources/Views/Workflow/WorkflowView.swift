import SwiftUI
import ModelKit

public struct WorkflowView: View {
  static let idealWidth: CGFloat = 500

  public enum SheetAction: Identifiable {
    case editCommand(ModelKit.Command)
    case editWorkflow(ModelKit.Workflow)

    public var id: String { return UUID().uuidString }
  }

  @Binding var workflow: Workflow
  @EnvironmentObject var userSelection: UserSelection
  let group: ModelKit.Group
  let applicationProvider: ApplicationProvider
  let commandController: CommandController
  let keyboardShortcutController: KeyboardShortcutController
  let openPanelController: OpenPanelController
  @ObservedObject var searchController: SearchController
  let workflowController: WorkflowController
  @Environment(\.colorScheme) var colorScheme
  @State var isDropping: Bool = false
  @State var showSearch: Bool = false
  @State var searchQuery: String = ""
  @State var sheetAction: SheetAction?

  public var body: some View {
    ScrollView {
      VStack {
        headerSection
        keyboardSection
      }.background(Color(.textBackgroundColor))
      commandSection
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
    .toolbar(content: {
      ToolbarItemGroup(placement: .automatic) {
        SearchField(query: Binding<String>(
                      get: { searchQuery },
                      set: {
                        searchQuery = $0
                        searchController.perform(.search($0))

                        if showSearch == $0.isEmpty {
                          showSearch = !$0.isEmpty
                        }
                      }))
          .frame(minWidth: 100, idealWidth: 200, maxWidth: .infinity)
          .padding(.horizontal, 12)
          .popover(isPresented: $showSearch, arrowEdge: .bottom, content: {
            SearchView(searchController: searchController)
              .frame(width: 300, alignment: .center)
              .frame(minHeight: 300, maxHeight: 500)
          })
      }

      ToolbarItemGroup {
        Spacer()
        Button(action: { sheetAction = nil },
               label: {
                Image(systemName: "plus.app")
                  .renderingMode(.template)
                  .foregroundColor(Color(.systemGray))
               })
          .help("Add Command to \"\(workflow.name)\"")
      }
    })
    .sheet(item: $sheetAction, content: { action in
      switch action {
      case .editCommand(let command):
        EditCommandView(
          applicationProvider: applicationProvider,
          openPanelController: openPanelController,
          saveAction: { newCommand in
            commandController.action(.updateCommand(newCommand, in: workflow))()
            sheetAction = nil
          },
          cancelAction: {
            sheetAction = nil
          },
          selection: command,
          command: command)
      case .editWorkflow(let workflow):
        EditCommandView(
          applicationProvider: applicationProvider,
          openPanelController: openPanelController,
          saveAction: { newCommand in
            commandController.action(.createCommand(newCommand, in: workflow))()
            sheetAction = nil
          },
          cancelAction: {
            sheetAction = nil
          },
          selection: Command.application(.init(application: Application.empty())),
          command: Command.application(.init(application: Application.empty())))
      }
    })
  }
}

private extension WorkflowView {
  var headerSection: some View {
    name(workflow, in: group)
      .padding([.horizontal, .top])
      .background(Color(.textBackgroundColor))
  }

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

  var keyboardSection: some View {
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
        KeyboardShortcutList(keyboardShortcutController: keyboardShortcutController,
                             keyboardShortcuts: workflow.keyboardShortcuts,
                             workflow: $workflow)
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
          .padding(.top)
          .cornerRadius(8.0)
      }
    }.padding(.horizontal, 8)
  }

  var commandSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      HeaderView(title: "Commands:")
        .padding([.leading, .top])
      if workflow.commands.isEmpty {
        VStack {
          AddButton(text: "Add Command",
                    alignment: .center,
                    action: { sheetAction = .editWorkflow(workflow) })
            .padding(.vertical, 8)
        }
      } else {
        CommandListView(workflow: $workflow) { action in
          switch action {
          case .reveal(let command):
            commandController.perform(.revealCommand(command, in: workflow))
          case .run(let command):
            commandController.perform(.runCommand(command))
          case .move(let command, let offset):
            commandController.perform(.moveCommand(command, offset: offset, in: workflow))
          case .edit(let command):
            sheetAction = .editCommand(command)
          case .delete(let command):
            commandController.perform(.deleteCommand(command, in: workflow))
          }
        }
          .frame(alignment: .top)
          .padding(.bottom, 24)
          .shadow(color: Color(.separatorColor).opacity(0.05), radius: 5, x: 0, y: 2.5)
          .padding(.top)
      }
    }
  }
}

// MARK: - Previews

struct WorkflowView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    DesignTimeFactory().workflowDetail(
      .constant(ModelFactory().workflowDetail()),
      group: ModelFactory().groupList().first!)
      .environmentObject(UserSelection())
      .frame(height: 668)
  }
}
