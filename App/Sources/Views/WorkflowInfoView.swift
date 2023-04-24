import Inject
import SwiftUI

struct WorkflowInfoView: View {
  @ObserveInjection var inject
  enum Action {
    case updateName(name: String)
    case setIsEnabled(isEnabled: Bool)
  }

  @ObservedObject private var detailPublisher: DetailPublisher
  @State var workflowName: String
  @State var isEnabled: Bool
  private var onAction: (Action) -> Void

  init(_ detailPublisher: DetailPublisher, onAction: @escaping (Action) -> Void) {
    _workflowName = .init(initialValue: detailPublisher.data.name)
    _isEnabled = .init(initialValue: detailPublisher.data.isEnabled)
    self.detailPublisher = detailPublisher
    self.onAction = onAction
  }

  var body: some View {
    HStack(spacing: 0) {
      TextField("Workflow name", text: $workflowName)
        .frame(height: 32)
        .textFieldStyle(LargeTextFieldStyle())
        .onChange(of: workflowName) { newValue in
          onAction(.updateName(name: newValue))
        }
      Spacer()
      Toggle("", isOn: $isEnabled)
        .toggleStyle(SwitchToggleStyle())
        .tint(Color.green)
        .font(.callout)
        .onChange(of: isEnabled) { newValue in
          onAction(.setIsEnabled(isEnabled: newValue))
        }
    }
    .debugEdit()
    .enableInjection()
  }
}
