import Inject
import SwiftUI

struct BezelNotificationViewModel: Identifiable, Hashable {
  var id: String
  var text: String
}

@MainActor
struct BezelNotificationView: View {
  @ObserveInjection var inject
  @ObservedObject var publisher: BezelNotificationPublisher
  @EnvironmentObject var manager: WindowManager
  @State var show: Bool = false

  init(publisher: BezelNotificationPublisher) {
    self.publisher = publisher
  }

  var body: some View {
    Text(publisher.data.text)
      .font(.largeTitle)
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background(backgroundView)
      .padding(.top, show ? 38 : -32)
      .frame(maxWidth: .infinity)
      .onReceive(publisher.$data, perform: { _ in
        show = true
        manager.close(after: .seconds(2), then: {
          show = false
        })
      })
      .scaleEffect(show ? 1 : 0.2, anchor: .top)
      .opacity(show ? 1 : 0)
      .animation(.interactiveSpring(duration: 0.275), value: show)
      .enableInjection()
  }

  private var backgroundView: some View {
    Color(.black)
      .opacity(publisher.data.text.isEmpty ? 0 : 1)
      .cornerRadius(8)
  }
}

struct NotificationBezel_Previews: PreviewProvider {
  static var publisher = BezelNotificationPublisher(.init(id: UUID().uuidString, text: ""))
  static var previews: some View {
    ZStack {
      BezelNotificationView(publisher: publisher)
        .background(Color(.systemGray))
    }
    .onAppear {
      withAnimation(.default.delay(1)) {
        publisher.publish(.init(id: UUID().uuidString, text: "Hello, world!"))
      }
    }
  }
}
