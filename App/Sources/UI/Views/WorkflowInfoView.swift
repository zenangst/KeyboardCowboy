import Bonzai
import Inject
import Carbon
import SwiftUI

struct WorkflowInfoView: View {
  @EnvironmentObject private var transaction: UpdateTransaction
  @EnvironmentObject private var updater: ConfigurationUpdater
  @ObserveInjection var inject
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
        .focused(focus, equals: .detail(.name))
        .textFieldStyle(
          .zen(
            .init(
              calm: true,
              backgroundColor: Color(nsColor: .windowBackgroundColor),
              font: .title2,
              padding: .init(horizontal: .small, vertical: .small),
              unfocusedOpacity: 0
            )
          )
        )
        .fontWeight(.bold)
        .onChange(of: name) { newName in
          guard newName != publisher.data.name else { return }
          publisher.data.name = newName
          updater.modifyWorkflow(using: transaction) { workflow in
            workflow.name = newName
          }
        }
      Spacer()
      ZenToggle(
        config: .init(color: .systemGreen),
        style: .medium,
        isOn: $publisher.data.isEnabled
      ) { newValue in
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.isEnabled = newValue
        }
      }
    }
    .enableInjection()
  }
}

struct WorkflowInfo_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowInfoView($focus, publisher: .init(DesignTime.detail.info), onInsertTab: { })
      .padding()
  }
}
