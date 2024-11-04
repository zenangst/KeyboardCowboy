import Bonzai
import Inject
import SwiftUI

struct CurrentUserModesView: View {
  @ObservedObject var publisher: UserSpace.UserModesPublisher

  var body: some View {
    ForEach(publisher.activeModes) { mode in
      Button(action: {}, label: {
        Text(mode.name)
          .font(.caption)
      })
      .buttonStyle(.zen(ZenStyleConfiguration(hoverEffect: .constant(false))))
    }
    .padding(4)
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
