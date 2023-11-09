import SwiftUI
import Bonzai

struct WorkflowInfoView: View {
  enum Action {
    case updateName(name: String)
    case setIsEnabled(isEnabled: Bool)
  }

  @EnvironmentObject var contentSelectionManager: SelectionManager<ContentViewModel>
  @EnvironmentObject var selection: SelectionManager<CommandViewModel>
  @ObservedObject private var publisher: InfoPublisher
  var focus: FocusState<AppFocus?>.Binding
  private let onInsertTab: () -> Void
  private var onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding, 
       publisher: InfoPublisher,
       onInsertTab: @escaping () -> Void,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.publisher = publisher
    self.onInsertTab = onInsertTab
    self.onAction = onAction
  }

  var body: some View {
    HStack(spacing: 0) {
      VStack {
        TextField("Workflow name", text: $publisher.data.name)
          .frame(height: 41)
          .fixedSize(horizontal: false, vertical: true)
          .focused(focus, equals: .detail(.name))
          .onCommand(#selector(NSTextField.insertTab(_:)), perform: onInsertTab)
          .onCommand(#selector(NSTextField.insertBacktab(_:)), perform: {
            let first = contentSelectionManager.selections.first ?? ""
            focus.wrappedValue = .workflow(contentSelectionManager.lastSelection ?? first)
          })
          .textFieldStyle(.large(color: .custom(selection.selectedColor),
                                 backgroundColor: Color(nsColor: .windowBackgroundColor),
                                 glow: true))
          .onChange(of: publisher.data.name) { onAction(.updateName(name: $0)) }
      }

      Spacer()
      ZenToggle("", config: .init(color: .systemGreen), isOn: $publisher.data.isEnabled) { onAction(.setIsEnabled(isEnabled: $0))
      }
    }
  }
}

struct WorkflowInfo_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowInfoView($focus,
                     publisher: .init(DesignTime.detail.info),
                     onInsertTab: { }) { _ in }
      .environmentObject(SelectionManager<CommandViewModel>())
      .padding()
  }
}
