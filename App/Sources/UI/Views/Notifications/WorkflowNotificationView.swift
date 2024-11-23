import Apps
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
  @Namespace var namespace

  var body: some View {
    VStack(alignment: getHorizontalAlignment(notificationPlacement)) {
      let maxHeight = NSScreen.main?.visibleFrame.height ?? 700
      WorkflowNotificationMatchesView(publisher: publisher)
        .frame(
          maxHeight: maxHeight,
          alignment: notificationPlacement.alignment
        )
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(4)
        .opacity(publisher.data.matches.isEmpty ? 0 : 1)

      RunningWorkflowView(publisher: publisher)
    }
    .padding(4)
    .onReceive(publisher.$data, perform: { newValue in
      if newValue.matches.isEmpty {
        windowManager.close(after: .seconds(1))
      } else {
        windowManager.cancelClose()
      }
    })
  }

  func getHorizontalAlignment(_ placement: NotificationPlacement) -> HorizontalAlignment {
    switch placement {
    case .center:         .center
    case .leading:        .leading
    case .trailing:       .trailing
    case .top:            .center
    case .bottom:         .center
    case .topLeading:     .leading
    case .topTrailing:    .trailing
    case .bottomLeading:  .leading
    case .bottomTrailing: .trailing
    }

  }
}

private struct RunningWorkflowView: View {
  @ObservedObject var publisher: WorkflowNotificationPublisher
  var body: some View {
    HStack {
      if let workflow = publisher.data.workflow {
        workflow.iconView(24)
      }

      ForEach(publisher.data.keyboardShortcuts, id: \.id) { keyShortcut in
        WorkflowNotificationKeyView(keyShortcut: keyShortcut, glow: .constant(false))
          .transition(AnyTransition.moveAndFade.animation(WorkflowNotificationView.animation))
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
          .transition(AnyTransition.moveAndFade.animation(WorkflowNotificationView.animation))
      }
    }
    .roundedContainer(padding: 6, margin: 0)
    .opacity(!publisher.data.keyboardShortcuts.isEmpty ? 1 : 0)
    .frame(height: !publisher.data.keyboardShortcuts.isEmpty ? nil : 0)
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
          glow: $glow
        )
        .frame(minWidth: modifier == .leftCommand || modifier == .leftShift ? 40 : 28, minHeight: 28)
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
      .init(id: "a", key: "a")
    ]
  )

  static let fullModel = WorkflowNotificationViewModel(
    id: "test",
    matches: [
      Workflow(
        name: "Finder",
        trigger: Workflow.Trigger.keyboardShortcuts(
          KeyboardShortcutTrigger(
            shortcuts: [
              KeyShortcut(key: "d", modifiers: [.leftControl, .leftOption, .leftCommand]),
              KeyShortcut(key: "f", modifiers: []),
            ]
          )
        ),
        commands: [
          Command.application(
            ApplicationCommand(
              action: .open,
              application: Application.finder(),
              meta: Command.MetaData(),
              modifiers: []
            )
          )
        ]
      )
    ],
    keyboardShortcuts: [
      KeyShortcut(key: "d", modifiers: [.leftControl, .leftOption, .leftCommand]),
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
  @MainActor @ViewBuilder
  func iconView(_ size: CGFloat) -> some View {
    let enabledCommands = Array(commands.filter(\.isEnabled).prefix(3).reversed())
    ZStack {
      ForEach(Array(zip(enabledCommands.indices, enabledCommands)), id: \.1.id) { offset, command in
        command.iconView(size)
          .id(command.id)
      }
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
    PlaceholderIconView(size: 32)
  }

  @MainActor @ViewBuilder
  func iconView(_ size: CGFloat) -> some View {
    switch self {
      case .builtIn(let builtInCommand):      BuiltinIconBuilder.icon(builtInCommand.kind, size: size)
      case .bundled(let bundled):
      switch bundled.kind {
      case .appFocus: AppFocusIcon(size: size)
      case .workspace: WorkspaceIcon(size: size)
      }
      case .mouse:                            MouseIconView(size: size)
      case .systemCommand(let systemCommand): SystemIconBuilder.icon(systemCommand.kind, size: size)
      case .menuBar:                          MenuIconView(size: size)
      case .windowManagement:                 WindowManagementIconView(size: size)
      case .uiElement:                        UIElementIconView(size: size)
      case .script(let command):
        switch command.kind {
          case .shellScript:                  ScriptIconView(size: size)
          case .appleScript:                  ScriptIconView(size: size)
        }
      case .application(let command):         IconView(icon: Icon(command.application), size: CGSize(width: size + 6, height: size + 6))
      case .text(let command):
        switch command.kind {
          case .insertText: TypingIconView(size: size)
        }
      case .keyboard(let model):
        let letters = model.keyboardShortcuts.map(\.key).joined()
        KeyboardIconView(letters, size: size)
      case .open(let command):
        if let application = command.application {
          IconView(
            icon: .init(application),
            size: .init(width: size + 6, height: size + 6)
          )
          .iconShape(size)
        } else {
          placeholderView(size)
        }
    case .shortcut:
      WorkflowShortcutImage(size: size)
    }
  }
}
