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
  @State private var workItem: DispatchWorkItem?

  init(publisher: BezelNotificationPublisher) {
    self.publisher = publisher
  }

  var body: some View {
    HStack {
      if publisher.data.running {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: Color(.systemPink)))
          .scaleEffect(0.75, anchor: .center)
        Text("Running…")
          .font(.title)
          .allowsTightening(true)
          .opacity(publisher.data.running ? 0.5 : 0.25)
          .animation(.easeInOut.repeatForever(), value: publisher.data.running)
      } else {
        Text(publisher.data.text)
          .font(.title)
          .allowsTightening(true)
      }
    }
    .animation(.smooth, value: publisher.data.text)
    .onReceive(publisher.$data, perform: { _ in
      show = true
      let workItem = DispatchWorkItem {
        withAnimation(.easeInOut(duration: 0.5)) {
          show = false
        }
      }
      self.workItem?.cancel()
      self.workItem = workItem
      DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    })
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
    .background(backgroundView)
    .frame(maxWidth: .infinity)
    .padding(.top, (show || publisher.data.running) ? 24 : 0)
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
      .padding(8)
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
