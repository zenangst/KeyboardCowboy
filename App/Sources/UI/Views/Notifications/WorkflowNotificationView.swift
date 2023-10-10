import SwiftUI
import Inject
import ZenViewKit

extension AnyTransition {
  static var moveAndFade: AnyTransition {
    .asymmetric(
      insertion: 
          .scale(scale: 0, anchor: .trailing)
          .combined(with: .opacity)
      ,
      removal: 
          .scale.combined(with: .opacity)
    )
  }
}

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

  var body: some View {
    VStack(alignment: .trailing) {
      if !publisher.data.matches.isEmpty {
        ScrollView {
          LazyVStack(alignment: .trailing) {
            ForEach(publisher.data.matches, id: \.id) { workflow in
              HStack {
                Text(workflow.name)
                switch workflow.trigger {
                case .keyboardShortcuts(let trigger):
                  ForEach(trigger.shortcuts) { shortcut in
                    WorkflowNotificationKeyView(keyShortcut: shortcut, glow: .constant(false))
                  }
                case .application, .none:
                  EmptyView()
                }
              }
              .frame(alignment: .trailing)
              .transition(AnyTransition.moveAndFade.animation(Self.animation))
            }
          }
          .padding()
        }
        .scrollIndicators(.hidden)
        .frame(height: 300)
        .padding(4)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }

      Spacer()

      HStack {
        Spacer()
        ForEach(publisher.data.keyboardShortcuts, id: \.stringValue) { keyShortcut in
          WorkflowNotificationKeyView(keyShortcut: keyShortcut, glow: Binding<Bool>(get: {
            publisher.data.glow
          }, set: { _ in }))
          .transition(AnyTransition.moveAndFade.animation(Self.animation))
        }

        if let workflow = publisher.data.workflow {
          Text(workflow.name)
            .textStyle(.zen)
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
    .frame(alignment: .trailing)
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
//      .onAppear {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//          withAnimation(WorkflowNotificationView.animation) {
//            publisher.publish(singleModel)
//          }
//
//          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            withAnimation(WorkflowNotificationView.animation) {
//              publisher.publish(fullModel)
//            }
//          }
//        }
//      }
  }
}
