import Bonzai
import SwiftUI

extension AnyTransition {
  static var moveAndFade: AnyTransition {
    .asymmetric(
      insertion:
          .scale(scale: 0.1, anchor: .trailing)
          .combined(with: .opacity)
      ,
      removal:
          .scale.combined(with: .opacity)
    )
  }
}

struct WorkflowNotificationMatchesView: View {
  static var animation: Animation = .smooth(duration: 0.2)
  @ObservedObject var publisher: WorkflowNotificationPublisher

  var body: some View {
    if !publisher.data.matches.isEmpty {
      ScrollView {
        LazyVStack(alignment: .trailing) {
          ForEach(publisher.data.matches, id: \.id) { workflow in
            HStack {
              workflow.iconView(24)
              Text(workflow.name)
                .font(.caption)
              Spacer()
              switch workflow.trigger {
              case .keyboardShortcuts(let trigger):
                ForEach(trigger.shortcuts) { shortcut in
                  WorkflowNotificationKeyView(keyShortcut: shortcut, glow: .constant(false))
                }
              case .application, .none, .snippet:
                EmptyView()
              }
            }
            .frame(alignment: .trailing)
            .transition(AnyTransition.moveAndFade.animation(Self.animation))
          }
        }
      }
      .frame(maxHeight: .infinity)
      .roundedContainer(padding: 8, margin: 0)
      .scrollIndicators(.hidden)
    }
  }
}

struct WorkflowNotificationMatchesView_Previews: PreviewProvider {
  static let publisher: WorkflowNotificationPublisher = .init(
    .init(
      id: UUID().uuidString,
      matches: [
        .empty()
      ],
      glow: false,
      keyboardShortcuts: []
    )
  )
  static var previews: some View {
    WorkflowNotificationMatchesView(publisher: publisher)
  }
}
