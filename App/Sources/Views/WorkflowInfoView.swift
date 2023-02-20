import SwiftUI

struct WorkflowInfoView: View {
  enum Action {
    case updateName(name: String)
    case setIsEnabled(isEnabled: Bool)
  }

  @ObservedObject private var detailPublisher: DetailPublisher
  private var onAction: (Action) -> Void

  init(_ detailPublisher: DetailPublisher, onAction: @escaping (Action) -> Void) {
    self.detailPublisher = detailPublisher
    self.onAction = onAction
  }

  var body: some View {
    HStack(spacing: 0) {
      TextField("Workflow name", text: $detailPublisher.model.name)
        .textFieldStyle(LargeTextFieldStyle())
        .frame(minHeight: 32)
        .onChange(of: detailPublisher.model.name) { newValue in
          onAction(.updateName(name: newValue))
        }
      Spacer()
      Toggle("", isOn: $detailPublisher.model.isEnabled)
        .toggleStyle(SwitchToggleStyle())
        .tint(Color.green)
        .font(.callout)
        .onChange(of: detailPublisher.model.isEnabled) { newValue in
          onAction(.setIsEnabled(isEnabled: newValue))
        }
    }
  }
}
