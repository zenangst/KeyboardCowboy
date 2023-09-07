import SwiftUI

struct WorkflowInfoView: View {
  @ObserveInjection var inject
  enum Action {
    case updateName(name: String)
    case setIsEnabled(isEnabled: Bool)
  }

  private let debounce: DebounceManager<String>
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
        .textFieldStyle(LargeTextFieldStyle())
        .onChange(of: workflowName) { debounce.send($0) }

      Spacer()
      AppToggle("", onColor: Color(.systemGreen), isOn: $isEnabled) { onAction(.setIsEnabled(isEnabled: $0)) }
    }
  }
}
