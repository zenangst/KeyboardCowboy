import Bonzai
import Carbon
import SwiftUI

struct WorkflowInfoView: View {
  enum Action {
    case updateName(name: String)
    case setIsEnabled(isEnabled: Bool)
  }

  @EnvironmentObject var contentSelectionManager: SelectionManager<ContentViewModel>
  @EnvironmentObject var selection: SelectionManager<CommandViewModel>
  @ObservedObject private var publisher: InfoPublisher
  @State var monitor: Any?
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
      TextField("Workflow name", text: $publisher.data.name)
        .frame(height: 41)
        .fixedSize(horizontal: false, vertical: true)
        .focused(focus, equals: .detail(.name))
        .textFieldStyle(.large(color: ZenColorPublisher.shared.color,
                               backgroundColor: Color(nsColor: .windowBackgroundColor),
                               glow: true))
        .onChange(of: publisher.data.name) { onAction(.updateName(name: $0)) }
        .onChange(of: focus.wrappedValue, perform: { value in
          if case .detail(.name) = value {
            if let oldMonitor = monitor { NSEvent.removeMonitor(oldMonitor) }

            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
              if event.keyCode == kVK_Tab {
                if event.modifierFlags.contains(.shift) {
                  focus.wrappedValue = .workflow(publisher.data.id)
                } else {
                  onInsertTab()
                }
                return nil
              }
              return event
            }
          } else if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
          }
        })

      Spacer()
      ZenToggle("", config: .init(color: .systemGreen), isOn: $publisher.data.isEnabled) { onAction(.setIsEnabled(isEnabled: $0))
      }
    }
    .onDisappear {
      if let monitor {
        NSEvent.removeMonitor(monitor)
        self.monitor = nil
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
