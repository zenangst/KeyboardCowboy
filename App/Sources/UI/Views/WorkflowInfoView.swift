import Bonzai
import Inject
import Carbon
import SwiftUI

struct WorkflowInfoView: View {
  enum Action {
    case updateName(name: String)
    case setIsEnabled(isEnabled: Bool)
  }

  @ObserveInjection var inject
  @ObservedObject private var publisher: InfoPublisher
  @State var name: String

  private let onInsertTab: () -> Void
  private var onAction: (Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       publisher: InfoPublisher,
       onInsertTab: @escaping () -> Void,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    _name = .init(initialValue: publisher.data.name)
    self.publisher = publisher
    self.onInsertTab = onInsertTab
    self.onAction = onAction
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
              font: .headline,
              padding: .init(horizontal: .small, vertical: .small),
              unfocusedOpacity: 0
            )
          )
        )
        .onChange(of: name) {
          guard $0 != publisher.data.name else { return }
          publisher.data.name = $0
          onAction(.updateName(name: $0))
        }
      Spacer()
      ZenToggle(
        config: .init(color: .systemGreen),
        style: .medium,
        isOn: $publisher.data.isEnabled
      ) { onAction(.setIsEnabled(isEnabled: $0))
      }
    }
    .enableInjection()
  }
}

struct WorkflowInfo_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowInfoView($focus,
                     publisher: .init(DesignTime.detail.info),
                     onInsertTab: { }) { _ in }
      .padding()
  }
}
