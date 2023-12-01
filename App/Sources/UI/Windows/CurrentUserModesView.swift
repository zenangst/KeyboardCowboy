import Bonzai
import Inject
import SwiftUI

struct CurrentUserModesView: View {
  @ObserveInjection var inject
  @ObservedObject var publisher: UserSpace.UserModesPublisher

  var body: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        ForEach(publisher.activeModes) { mode in
          Button(action: {}, label: {
            Text(mode.name)
              .font(.caption)
          })
          .buttonStyle(.zen(ZenStyleConfiguration(hoverEffect: .constant(false))))
        }
      }
      .padding(4)
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
