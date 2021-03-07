import ModelKit
import SwiftUI
import MbSwiftUIFirstResponder

struct DetailToolbarConfig {
  var showSearch: Bool = false
  var searchQuery: String = ""
}

public struct DetailView: View {
  enum FirstResponders: Int {
    case name
  }

  public enum ViewState {
    case empty
    case workflow(ModelKit.Workflow)
  }

  public enum Action {
    case set(workflow: Workflow)
  }

  let context: ViewKitFeatureContext
  @ObservedObject var workflowController: WorkflowController
  @EnvironmentObject private var keyInputSubjectWrapper: KeyInputSubjectWrapper
  @State private var selectedCommand: Command?
  @State private var sheet: CommandListView.Sheet?
  @State private var config = DetailToolbarConfig()
  @State private var isDropping: Bool = false
  @Binding private var firstResponder: FirstResponders?

  init(context: ViewKitFeatureContext,
       firstResponder: Binding<FirstResponders?> = .constant(nil),
       workflowController: WorkflowController) {
    self.context = context
    _firstResponder = firstResponder
    self.workflowController = workflowController
  }

  public var body: some View {
    ScrollView {
      VStack {
        VStack(alignment: .leading) {
          TextField("", text: workflow.name)
            .firstResponder(id: FirstResponders.name, firstResponder: $firstResponder)
            .font(.largeTitle)
            .foregroundColor(.primary)
            .textFieldStyle(PlainTextFieldStyle())
          HeaderView(title: "Keyboard shortcuts:").padding([.top])
          KeyboardShortcutList(workflow: workflow,
                               performAction: context.keyboardsShortcuts.perform(_:))
            .cornerRadius(8)
        }.padding()
      }
      .padding([.leading, .trailing, .bottom], 8)
      .background(Color(.textBackgroundColor))

      VStack(alignment: .leading) {
        HeaderView(title: "Commands:")
                .padding([.leading, .top])
        CommandListView(selection: $selectedCommand,
                        workflow: workflow,
                        perform: context.commands.perform(_:),
                        receive: { sheet = $0 })
          .onReceive(context.keyInputSubjectWrapper, perform: receive(_:))
      }
      .padding(8)
      .onDrop($isDropping) { urls in
        context.commands.perform(.drop(urls, workflowController.state))
      }.overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.accentColor, lineWidth: isDropping ? 5 : 0)
          .padding(4)
      )
    }.toolbar(content: {
      DetailViewToolbar(
        config: $config,
        sheet: $sheet,
        workflowName: workflowController.state.name,
        searchController: context.search)
    })
    .background(gradient)
    .sheet(item: $sheet, content: { receive($0) })
  }
}

// MARK: Extensions

extension DetailView {
  var workflow: Binding<Workflow> {
    Binding<Workflow>(get: {
      workflowController.state
    }, set: {
      firstResponder = .name
      workflowController.perform(.set(workflow: $0))
    })
  }

  var gradient: some View {
    LinearGradient(
      gradient: Gradient(
        stops: [
          .init(color: Color(.windowBackgroundColor).opacity(0.25), location: 0.8),
          .init(color: Color(.gridColor).opacity(0.75), location: 1.0),
        ]),
      startPoint: .top,
      endPoint: .bottom)
  }

  @ViewBuilder
  func receive(_ action: CommandListView.Sheet) -> some View {
    switch action {
    case .create(let command):
      EditCommandView(applicationProvider: context.applicationProvider,
                      openPanelController: context.openPanel,
                      saveAction: { newCommand in
                        context.commands.perform(.create(newCommand, in: workflowController.state))
                        sheet = nil
                      },
                      cancelAction: { sheet = nil },
                      selection: command,
                      command: command)
    case .edit(let command):
      EditCommandView(applicationProvider: context.applicationProvider, openPanelController: context.openPanel,
                      saveAction: { command in
                        context.commands.perform(.edit(command, in: workflowController.state))
                        sheet = nil
                      },
                      cancelAction: { sheet = nil },
                      selection: command,
                      command: command)
    }
  }

  func receive(_ subject: KeyInputSubjectWrapper.Output) {
    guard let command = selectedCommand,
          let index = workflowController.state.commands.firstIndex(of: command) else { return }

    let newIndex: Int

    switch subject {
    case .delete:
      context.commands.perform(.delete(command, in: workflowController.state))
      return
    case .upArrow:
      newIndex = max(index - 1, 0)
    case .downArrow:
      newIndex = min(index + 1, workflowController.state.commands.count - 1)
    default:
      return
    }

    selectedCommand = workflowController.state.commands[newIndex]
  }
}

// MARK: Previews

struct DetailView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let workflow = ModelFactory().workflowDetail()
    let context: ViewKitFeatureContext = .preview()

    context.workflow.perform(.set(workflow: workflow))

    return DetailView(
      context: context,
      workflowController: context.workflow)
  }
}

struct DetailViewPlaceHolder: View {
  var body: some View {
    Text("Select a workflow")
  }
}
