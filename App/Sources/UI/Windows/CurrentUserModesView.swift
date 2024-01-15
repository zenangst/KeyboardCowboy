import Bonzai
import Inject
import SwiftUI

struct CurrentUserModesView: View {
  @ObserveInjection var inject
  @ObservedObject var publisher: UserSpace.UserModesPublisher
  static var animation: Animation = .smooth(duration: 0.2)

  var body: some View {
    ForEach(publisher.activeModes) { mode in
      Button(action: {}, label: {
        Text(mode.name)
          .font(.caption)
      })
      .buttonStyle(.zen(ZenStyleConfiguration(hoverEffect: .constant(false))))
      .transition(AnyTransition.moveAndFade.animation(Self.animation))
    }
    .padding(4)
    .enableInjection()
  }
}

#Preview {
  let publisher = UserSpace.UserModesPublisher(
    [
      .init(id: UUID().uuidString, name: "foo", isEnabled: true),
      .init(id: UUID().uuidString, name: "bar", isEnabled: true),
      .init(id: UUID().uuidString, name: "baz", isEnabled: true),
    ]
  )
  return CurrentUserModesView(publisher: publisher)
    .padding()
}
