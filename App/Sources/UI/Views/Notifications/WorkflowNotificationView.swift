import SwiftUI
import Inject
import Bonzai

struct WorkflowNotificationViewModel: Identifiable, Hashable {
  var id: String
  var workflow: Workflow?
  var matches: [Workflow] = []
  var glow: Bool = false
  let keyboardShortcuts: [KeyShortcut]
}

enum NotificationPlacement: String, RawRepresentable {
  case center
  case leading
  case trailing
  case top
  case bottom
  case topLeading
  case topTrailing
  case bottomLeading
  case bottomTrailing

  var alignment: Alignment {
    switch self {
    case .center: .center
    case .leading: .leading
    case .trailing: .trailing
    case .top: .top
    case .bottom: .bottom
    case .topLeading: .topLeading
    case .topTrailing: .topTrailing
    case .bottomLeading: .bottomLeading
    case .bottomTrailing: .bottomTrailing
    }
  }
}

struct WorkflowNotificationView: View {
  static var animation: Animation = .smooth(duration: 0.2)
  @ObservedObject var publisher: WorkflowNotificationPublisher
  @EnvironmentObject var windowManager: WindowManager
  @AppStorage("Notifications.Placement") var notificationPlacement: NotificationPlacement = .bottomLeading

  var body: some View {
    NotificationView(notificationPlacement.alignment) {
      WorkflowNotificationMatchesView(publisher: publisher)
        .frame(maxWidth: 250, maxHeight: 500, alignment: notificationPlacement.alignment)
        .fixedSize(horizontal: false, vertical: true)
      HStack {
        if let workflow = publisher.data.workflow {
          workflow.iconView(24)
        }

        ForEach(publisher.data.keyboardShortcuts, id: \.id) { keyShortcut in
          WorkflowNotificationKeyView(keyShortcut: keyShortcut, glow: .readonly(false))
          .transition(AnyTransition.moveAndFade.animation(Self.animation))
        }

        if let workflow = publisher.data.workflow {
          Text(workflow.name)
            .allowsTightening(true)
            .minimumScaleFactor(0.8)
            .bold()
            .font(.footnote)
            .lineLimit(1)
            .padding(4)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .transition(AnyTransition.moveAndFade.animation(Self.animation))
        }
      }
      .roundedContainer(padding: 6, margin: 0)
    }
    .padding(4)
    .onReceive(publisher.$data, perform: { newValue in
      guard let screen = NSScreen.main else { return }

      windowManager.window?.setFrame(
        NSRect(origin: .zero,
               size: screen.visibleFrame.size),
        display: false,
        animate: false
      )

      if newValue.matches.isEmpty {
        windowManager.close(after: .seconds(1))
      } else {
        windowManager.cancelClose()
      }
    })
  }
}

struct WorkflowNotificationKeyView: View {
  let keyShortcut: KeyShortcut
  @Binding var glow: Bool

  var body: some View {
    HStack(spacing: 6) {
      ForEach(keyShortcut.modifiers) { modifier in
        ModifierKeyIcon(
          key: modifier,
          alignment: keyShortcut.lhs
          ? modifier == .shift ? .bottomLeading : .topTrailing
          : modifier == .shift ? .bottomTrailing : .topLeading,
          glow: $glow
        )
        .frame(minWidth: modifier == .command || modifier == .shift ? 40 : 28, minHeight: 28)
        .fixedSize(horizontal: true, vertical: true)
      }
      RegularKeyIcon(letter: keyShortcut.key, width: 28, height: 28, glow: $glow)
        .fixedSize(horizontal: true, vertical: true)
    }
  }
}

struct WorkflowNotificationView_Previews: PreviewProvider {
  static let emptyModel = WorkflowNotificationViewModel(
    id: "test",
    keyboardShortcuts: [ ]
  )

  static let singleModel = WorkflowNotificationViewModel(
    id: "test",
    keyboardShortcuts: [ 
      .init(id: "a", key: "a", lhs: true)
    ]
  )

  static let fullModel = WorkflowNotificationViewModel(
    id: "test",
    matches: [
      Workflow.designTime(.keyboardShortcuts(.init(shortcuts: [
        .init(key: "a")
      ])))
    ],
    keyboardShortcuts: [
      .init(id: "a", key: "a", lhs: true),
      .init(id: "b", key: "b", lhs: true),
      .init(id: "c", key: "c", lhs: true),
    ]
  )

  static var publisher = WorkflowNotificationPublisher(fullModel)
  static var previews: some View {
    WorkflowNotificationView(publisher: publisher)
      .environmentObject(WindowManager())
      .padding(64)
  }
}

extension Workflow {
  @ViewBuilder
  func iconView(_ size: CGFloat) -> some View {
    let enabledCommands = commands.filter(\.isEnabled)
    if enabledCommands.count == 1, let command = enabledCommands.first {
      command.iconView(size)
    } else {
      PlaceholderIconView(size: size)
    }
  }
}

struct PlaceholderIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(.controlAccentColor).opacity(0.25))
      .overlay { iconBorder(size) }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

extension Command {
  func placeholderView(_ size: CGFloat) -> some View {
    PlaceholderIconView(size: size)
  }

  @ViewBuilder
  func iconView(_ size: CGFloat) -> some View {
    switch self {
    case .builtIn(let builtInCommand):
      switch builtInCommand.kind {
      case .macro(let action):
        switch action.kind {
        case .record: MacroIconView(.record, size: size)
        case .remove: MacroIconView(.remove, size: size)
        }
      case .userMode: UserModeIconView(size: size)
      }
    case .mouse:
      MouseIconView(size: size)
    case .systemCommand(let systemCommand):
      switch systemCommand.kind {
      case .activateLastApplication:
        ActivateLastApplicationIconView(size: size)
      case .applicationWindows:              MissionControlIconView(size: size)
      case .minimizeAllOpenWindows:          MinimizeAllIconView(size: size)
      case .moveFocusToNextWindow:           MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size)
      case .moveFocusToNextWindowFront:      MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size)
      case .moveFocusToNextWindowGlobal:     MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
      case .moveFocusToPreviousWindow:       MoveFocusToWindowIconView(direction: .previous, scope: .visibleWindows, size: size)
      case .moveFocusToPreviousWindowFront:  MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size)
      case .moveFocusToPreviousWindowGlobal: MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size)
      case .showDesktop:                     DockIconView(size: size)
      case .missionControl:                  MissionControlIconView(size: size)
      }
    case .menuBar: MenuIconView(size: size)
    case .windowManagement: WindowManagementIconView(size: size)
    case .uiElement: UIElementIconView(size: size)
    case .application(let command):
      IconView(
        icon: .init(command.application),
        size: .init(width: 32, height: 32)
      )
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
      .id(command.id)
    case .text(let command):
      switch command.kind {
      case .insertText: TypingIconView(size: size)
      }
    default:
      placeholderView(size)
    }
  }
}
