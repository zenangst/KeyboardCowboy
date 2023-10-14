import SwiftUI
import Inject
import ZenViewKit

struct WorkflowNotificationViewModel: Identifiable, Hashable {
  var id: String
  var workflow: Workflow?
  var matches: [Workflow] = []
  var glow: Bool = false
  let keyboardShortcuts: [KeyShortcut]
}

struct WorkflowNotificationView: View {
  static var animation: Animation = .smooth(duration: 0.2)
  @ObservedObject var publisher: WorkflowNotificationPublisher

  @EnvironmentObject var windowManager: WindowManager
  let alignment: Alignment = .bottomTrailing

  var body: some View {
    NotificationView(alignment) {
      WorkflowNotificationMatchesView(publisher: publisher)
        .frame(maxWidth: 250, maxHeight: 250, alignment: alignment)
      HStack {
        ForEach(publisher.data.keyboardShortcuts, id: \.id) { keyShortcut in
          WorkflowNotificationKeyView(keyShortcut: keyShortcut, glow: Binding<Bool>(get: {
            publisher.data.glow
          }, set: { _ in }))
          .transition(AnyTransition.moveAndFade.animation(Self.animation))
        }

        if let workflow = publisher.data.workflow {
          Text(workflow.name)
            .textStyle(.zen)
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
      .padding(4)
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
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
        .frame(minWidth: modifier == .command || modifier == .shift ? 44 : 32, minHeight: 32)
        .fixedSize(horizontal: true, vertical: true)
      }
      RegularKeyIcon(letter: keyShortcut.key, width: 32, height: 32, glow: $glow)
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
      .padding(64)
  }
}
