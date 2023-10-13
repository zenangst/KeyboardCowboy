import SwiftUI
import ZenViewKit

struct WorkflowInfoView: View {
  enum Action {
    case updateName(name: String)
    case setIsEnabled(isEnabled: Bool)
  }

  private let debounce: DebounceManager<String>
  @EnvironmentObject var selection: SelectionManager<CommandViewModel>
  @ObservedObject private var detailPublisher: DetailPublisher
  @State var workflowName: String
  @State var isEnabled: Bool
  var focus: FocusState<AppFocus?>.Binding
  private var onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding, detailPublisher: DetailPublisher, onAction: @escaping (Action) -> Void) {
    self.focus = focus
    _workflowName = .init(initialValue: detailPublisher.data.name)
    _isEnabled = .init(initialValue: detailPublisher.data.isEnabled)
    self.detailPublisher = detailPublisher
    self.onAction = onAction
    self.debounce = DebounceManager(for: .milliseconds(250)) { onAction(.updateName(name: $0)) }
  }

  var body: some View {
    HStack(spacing: 0) {
      VStack {
        TextField("Workflow name", text: $workflowName)
          .focused(focus, equals: .detail(.name))
          .onCommand(#selector(NSTextField.insertTab(_:)), perform: {
            switch detailPublisher.data.trigger {
            case .applications:
              focus.wrappedValue = .detail(.applicationTriggers)
            case .keyboardShortcuts:
              focus.wrappedValue = .detail(.keyboardShortcuts)
            case .none:
              focus.wrappedValue = .detail(.name)
            }
          })
          .onCommand(#selector(NSTextField.insertBacktab(_:)), perform: {
            focus.wrappedValue = .workflows
          })
          .fixedSize(horizontal: false, vertical: true)
          .frame(height: 32)
          .textFieldStyle(.large(color: .custom(selection.selectedColor), 
                                 backgroundColor: Color(nsColor: .windowBackgroundColor),
                                 glow: true))
          .onChange(of: workflowName) { debounce.send($0) }
      }

      Spacer()
      ZenToggle("", config: .init(color: .systemGreen), isOn: $isEnabled) { onAction(.setIsEnabled(isEnabled: $0)) }
    }
  }
}

struct WorkflowInfo_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowInfoView($focus, detailPublisher: .init(DesignTime.detail)) { _ in }
      .padding()
  }
}
