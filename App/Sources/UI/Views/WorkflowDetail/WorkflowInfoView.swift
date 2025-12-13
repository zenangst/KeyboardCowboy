import Bonzai
import Carbon
import HotSwiftUI
import SwiftUI

struct WorkflowInfoView: View {
  @EnvironmentObject private var transaction: UpdateTransaction
  @EnvironmentObject private var updater: ConfigurationUpdater
  @ObservedObject private var publisher: InfoPublisher
  @State var name: String

  private let onInsertTab: () -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding, publisher: InfoPublisher, onInsertTab: @escaping () -> Void) {
    self.focus = focus
    _name = .init(initialValue: publisher.data.name)
    self.publisher = publisher
    self.onInsertTab = onInsertTab
  }

  var body: some View {
    HStack(spacing: 0) {
      TextField("Workflow name", text: $name)
        .frame(maxWidth: .infinity)
        .focused(focus, equals: .detail(.name))
        .fontWeight(.semibold)
        .environment(\.textFieldCalm, true)
        .environment(\.textFieldFont, .title)
        .environment(\.textFieldPadding, .small)
        .environment(\.textFieldUnfocusedOpacity, 0)
        .onChange(of: name) { newName in
          guard newName != publisher.data.name else { return }

          publisher.data.name = newName
          updater.modifyWorkflow(using: transaction) { workflow in
            workflow.name = newName
          }
        }
      Spacer()
      Toggle(isOn: $publisher.data.isEnabled, label: {})
        .onChange(of: publisher.data.isEnabled) { newValue in
          updater.modifyWorkflow(using: transaction, withAnimation: .snappy(duration: 0.125)) { workflow in
            workflow.isDisabled = !newValue
          }
        }
        .switchStyle()
        .environment(\.switchStyle, .regular)
    }
    .onChange(of: publisher.data.name) { newValue in
      guard newValue != name else { return }

      name = newValue
    }
  }
}

struct WorkflowInfo_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowInfoView($focus, publisher: .init(DesignTime.detail.info), onInsertTab: {})
      .padding()
  }
}
