import SwiftUI
import Apps

struct SingleDetailView: View {
  @Namespace var namespace

  enum Action {
    case applicationTrigger(workflowId: Workflow.ID, action: WorkflowApplicationTriggerView.Action)
    case commandView(workflowId: Workflow.ID, action: CommandView.Action)
    case dropUrls(workflowId: Workflow.ID, urls: [URL])
    case moveCommand(workflowId: Workflow.ID, indexSet: IndexSet, toOffset: Int)
    case removeCommands(workflowId: Workflow.ID, commandIds: Set<Command.ID>)
    case removeTrigger(workflowId: Workflow.ID)
    case runWorkflow(workflowId: Workflow.ID)
    case setIsEnabled(workflowId: Workflow.ID, isEnabled: Bool)
    case trigger(workflowId: Workflow.ID, action: WorkflowTriggerView.Action)
    case updateExecution(workflowId: Workflow.ID, execution: DetailViewModel.Execution)
    case updateKeyboardShortcuts(workflowId: Workflow.ID, keyboardShortcuts: [KeyShortcut])
    case updateName(workflowId: Workflow.ID, name: String)
  }
  var focus: FocusState<AppFocus?>.Binding
  @ObserveInjection var inject
  @Environment(\.openWindow) var openWindow
  private var detailPublisher: DetailPublisher
  @State var overlayOpacity: CGFloat = 0
  private let onAction: (Action) -> Void

  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandSelectionManager: SelectionManager<DetailViewModel.CommandViewModel>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>


  init(_ focus: FocusState<AppFocus?>.Binding,
       detailPublisher: DetailPublisher,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<DetailViewModel.CommandViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.detailPublisher = detailPublisher
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.commandSelectionManager = commandSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.onAction = onAction
  }

  var body: some View {
    let shouldShowCommandList = detailPublisher.data.trigger != nil ||
                               !detailPublisher.data.commands.isEmpty
    ScrollViewReader { proxy in
        VStack(alignment: .leading) {
          WorkflowInfoView(focus, detailPublisher: detailPublisher, onAction: { action in
            switch action {
            case .updateName(let name):
              onAction(.updateName(workflowId: detailPublisher.data.id, name: name))
            case .setIsEnabled(let isEnabled):
              onAction(.setIsEnabled(workflowId: detailPublisher.data.id, isEnabled: isEnabled))
            }
          })
          .padding(.horizontal, 4)
          .padding(.vertical, 12)
          .id(detailPublisher.data.id)
          WorkflowTriggerListView(focus, data: detailPublisher.data,
                                  applicationTriggerSelectionManager: applicationTriggerSelectionManager,
                                  keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
                                  onAction: onAction)
            .id(detailPublisher.data.id)
        }
        .padding([.top, .leading, .trailing])
        .padding(.bottom, 32)
        .background(alignment: .bottom, content: {
          Rectangle()
            .fill(
              LinearGradient(stops: [
                .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.3, of: .white)!), location: 0.0),
                .init(color: Color(nsColor: .windowBackgroundColor), location: 0.01),
                .init(color: Color(nsColor: .windowBackgroundColor), location: 0.8),
                .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.3, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
            .mask(
              Canvas(rendersAsynchronously: true) { context, size in
                context.fill(
                  Path(CGRect(origin: .zero, size: CGSize(width: size.width,
                                                          height: size.height - 12))),
                  with: .color(Color(.black))
                )

                if shouldShowCommandList {
                  context.fill(Path { path in
                    path.move(to: CGPoint(x: size.width / 2, y: size.height - 12))
                    path.addLine(to: CGPoint(x: size.width / 2 - 24, y: size.height - 12))
                    path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 2))
                    path.addLine(to: CGPoint(x: size.width / 2 + 24, y: size.height - 12))
                    path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 12))
                  }, with: .color(Color(.black)))
                }
              }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2),
                       value: shouldShowCommandList)
            .compositingGroup()
            .shadow(color: Color.white.opacity(0.2), radius: 0, y: 1)
            .shadow(radius: 2, y: 2)
        })

      VStack(spacing: 0) {
        HStack {
          Label("Commands", image: "")
          Spacer()
          Group {
            Menu(content: {
              ForEach(DetailViewModel.Execution.allCases) { execution in
                Button(execution.rawValue, action: {
                  onAction(.updateExecution(workflowId: detailPublisher.data.id,
                                            execution: execution))
                })
              }
            }, label: {
              Image(systemName: "play.fill")
              Text("Run \(detailPublisher.data.execution.rawValue)")
            }, primaryAction: {
              onAction(.runWorkflow(workflowId: detailPublisher.data.id))
            })
            .padding(.horizontal, 2)
            .padding(.top, 3)
            .padding(.bottom, 1)
            .overlay(alignment: .trailing, content: {
              Rectangle()
                .fill(Color(.white).opacity(0.2))
                .frame(width: 1)
                .padding(.trailing, 18)
            })
            .background(
              RoundedRectangle(cornerRadius: 4)
                .stroke(Color(.white).opacity(0.2), lineWidth: 1)
            )
            .menuStyle(.borderlessButton)
            .frame(maxWidth: detailPublisher.data.execution == .concurrent ? 144 : 110,
                   alignment: .leading)
          }
          .opacity(detailPublisher.data.commands.isEmpty ? 0 : 1)

          if !detailPublisher.data.commands.isEmpty {
            Button(action: {
              openWindow(value: NewCommandWindow.Context.newCommand(workflowId: detailPublisher.data.id))
            }) {
              HStack(spacing: 4) {
                Image(systemName: "plus.app")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(maxWidth: 12, maxHeight: 12)
                  .padding(2)
                  .layoutPriority(-1)
              }
            }
            .padding(.horizontal, 4)
            .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
            .matchedGeometryEffect(id: "add-command-button", in: namespace, properties: .position)
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 6)

        ScrollView {
          WorkflowCommandListView(
            focus,
            namespace: namespace,
            publisher: detailPublisher,
            selectionManager: commandSelectionManager,
            scrollViewProxy: proxy,
            onAction: { action in
              onAction(action)
            })
        }
      }
      .opacity(shouldShowCommandList ? 1 : 0)
    }
    .labelStyle(HeaderLabelStyle())
    .focusScope(namespace)
    .debugEdit()
  }
}

struct SingleDetailView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    SingleDetailView($focus,
                     detailPublisher: .init(DesignTime.detail),
                     applicationTriggerSelectionManager: .init(),
                     commandSelectionManager: .init(),
                     keyboardShortcutSelectionManager: .init()) { _ in }
      .designTime()
      .frame(height: 900)
  }
}
