import SwiftUI

struct BezelNotificationViewModel: Identifiable, Hashable {
  var id: String { return text }
  let text: String
}

struct BezelNotificationView: View {
  @ObservedObject var publisher: BezelNotificationPublisher

  init(publisher: BezelNotificationPublisher) {
    self.publisher = publisher
  }

  var body: some View {
    Group {
      Text(publisher.data.text)
        .font(.largeTitle)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color(.windowBackgroundColor).opacity(0.5).cornerRadius(32))
        .padding(32)
        .frame(maxWidth: .infinity)
    }
  }
}

struct NotificationBezel_Previews: PreviewProvider {
  static var publisher = BezelNotificationPublisher(.init(text: ""))
  static var previews: some View {
    ZStack {
      BezelNotificationView(publisher: publisher)
        .background(Color(.systemGray))
    }
    .onAppear {
      withAnimation(.default.delay(5)) {
        publisher.publish(.init(text: "Hello, world!"))
      }
    }
  }
}
