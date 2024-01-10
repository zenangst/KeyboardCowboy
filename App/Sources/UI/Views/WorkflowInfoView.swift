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

  private let onInsertTab: () -> Void
  private var onAction: (Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

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
        .onChange(of: publisher.data.name) { onAction(.updateName(name: $0)) }
        .modifier(TabModifier(focus: focus, onInsertTab: onInsertTab))

      Spacer()
      ZenToggle(
        "",
        config: .init(color: .systemGreen),
        style: .medium,
        isOn: $publisher.data.isEnabled
      ) { onAction(.setIsEnabled(isEnabled: $0))
      }
    }
    .enableInjection()
  }
}

private struct TabModifier: ViewModifier {
  @State private var monitor: Any?
  private var focus: FocusState<AppFocus?>.Binding
  private let onInsertTab: () -> Void

  init(focus: FocusState<AppFocus?>.Binding, onInsertTab: @escaping () -> Void) {
    self.focus = focus
    self.onInsertTab = onInsertTab
  }

  func body(content: Content) -> some View {
    // This is a workaround for a bug in SwiftUI on Ventura where this method causes a recursion
    // and will eventually crash the app.
    if #available(macOS 14 , *) {
      content
      .onChange(of: focus.wrappedValue, perform: { value in
        if case .detail(.name) = value {
          if let oldMonitor = monitor { NSEvent.removeMonitor(oldMonitor) }

          monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.keyCode == kVK_Tab {
              if event.modifierFlags.contains(.shift) {
                focus.wrappedValue = .workflows
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
      .onDisappear {
        if let monitor {
          NSEvent.removeMonitor(monitor)
          self.monitor = nil
        }
      }
    } else {
      content
    }
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
