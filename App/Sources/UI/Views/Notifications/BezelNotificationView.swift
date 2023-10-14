import SwiftUI

struct BezelNotificationViewModel: Identifiable, Hashable {
  var id: String
  let text: String
}

struct BezelNotificationView: View {
  @ObservedObject var publisher: BezelNotificationPublisher
  @EnvironmentObject var manager: WindowManager

  init(publisher: BezelNotificationPublisher) {
    self.publisher = publisher
  }

  var body: some View {
    Text(publisher.data.text)
      .font(.largeTitle)
      .padding(.horizontal, 24)
      .padding(.vertical, 16)
      .background(backgroundView)
      .padding(32)
      .frame(maxWidth: .infinity)
      .onReceive(publisher.$data, perform: { _ in
        manager.close(after: .seconds(1))
      })
  }

  private var backgroundView: some View {
    Color(.windowBackgroundColor)
      .opacity(publisher.data.text.isEmpty ? 0 : 0.5)
      .cornerRadius(32)
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
