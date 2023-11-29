import Inject
import SwiftUI

struct BezelNotificationViewModel: Identifiable, Hashable {
  var id: String
  var text: String
  var running: Bool = false
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
    HStack {
      if publisher.data.running {
        Rectangle()
          .fill(Color.green)
          .mask {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
          }
          .frame(width: 24, height: 24)
        Text("Running…")
          .font(.title)
          .allowsTightening(true)
          .opacity(0.5)
      } else {
        Text(publisher.data.text)
          .font(.title)
          .allowsTightening(true)
      }
    }
    .onReceive(publisher.$data, perform: { _ in
      show = true
      manager.close(after: .seconds(2), then: {
        show = false
      })
    })
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
    .background(backgroundView)
    .padding(.top, (show || publisher.data.running) ? 36 : 0)
    .frame(maxWidth: .infinity)
    .scaleEffect((show || publisher.data.running) ? 1 : 0.01, anchor: .top)
    .opacity((show || publisher.data.running) ? 1 : 0)
    .animation(.smooth(duration: 0.5, extraBounce: 0.2), value: show)
    .animation(.smooth(duration: 0.5, extraBounce: 0.2), value: publisher.data.text)
    .padding(.bottom, 16)
      .enableInjection()
  }

  private var backgroundView: some View {
    Color(.black)
      .opacity(publisher.data.text.isEmpty ? 0 : 1)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .cornerRadius(12)
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
