import Apps
import SwiftUI
import UniformTypeIdentifiers

struct WorkflowView: View, Equatable {
  @ObserveInjection var inject
  enum Action {
    case workflow(WorkflowCommandsListView.Action)
  }
  enum Sheet: Identifiable {
    var id: String {
      switch self {
      case .edit(let command):
        return command.id
      }
    }
    case edit(Command)
  }

  let applicationStore: ApplicationStore
  @FocusState var focus: Focus?
  @Binding var sheet: Sheet?
  @Binding var workflow: Workflow
  @State private var dragOver: Bool = false

  var action: (Action) -> Void

  init(applicationStore: ApplicationStore,
       focus: FocusState<Focus?> = .init(),
       workflow: Binding<Workflow>,
       sheet: Binding<Sheet?>,
       action: @escaping (Action) -> Void) {
    _focus = focus
    _workflow = workflow
    _sheet = sheet
    self.applicationStore = applicationStore
    self.action = action
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        WorkflowInfoView(focus: _focus, workflow: $workflow)
        .equatable()
        .padding([.leading, .trailing, .bottom], 8)

        WorkflowShortcutsView(applicationStore, focus: _focus, workflow: $workflow)
          .equatable()
          .padding(8)
      }
      .padding()
      .background(Color(.textBackgroundColor))

      VStack(alignment: .leading) {
        WorkflowCommandsListView(workflow: $workflow, action: { action in
          switch action {
          case .commandView(let action):
            switch action {
            case .commandAction(let action):
              switch action {
              case .edit(let command):
                sheet = .edit(command)
              case .run, .reveal:
                break
              }
            }
          }
          self.action(.workflow(action))
        })
        .equatable()
        .padding(8)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.accentColor, lineWidth: 2)
            .opacity(dragOver ? 1.0 : 0.0)
        )
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $dragOver, perform: { providers, location in
          Task {
            var urls = [URL]()
            for provider in providers {
              if let data = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? Data,
                 let url = URL(dataRepresentation: data, relativeTo: nil) {
                urls.append(url)
              }
            }
          }
          return true
        })
      }.padding([.leading, .trailing])
    }
    .sheet(item: $sheet, content: { sheetType in
      switch sheetType {
      case .edit(let command):
        EditCommandView(applicationStore: applicationStore,
                        openPanelController: OpenPanelController(),
                        saveAction: { newCommand in
          workflow.updateOrAddCommand(newCommand)
          sheet = nil
        }, cancelAction: {
          sheet = nil
        }, selection: command, command: command)
      }
    })
    .background(gradient)
    .enableInjection()
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

  static func == (lhs: WorkflowView, rhs: WorkflowView) -> Bool {
    lhs.workflow == rhs.workflow
  }
}

struct WorkflowView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowView(
      applicationStore: ApplicationStore(),
      workflow: .constant(Workflow.designTime(
      .keyboardShortcuts( [
        .init(key: "A", modifiers: [.command]),
        .init(key: "B", modifiers: [.function]),
      ])
      )),
      sheet: .constant(nil),
      action: { _ in })
  }
}
