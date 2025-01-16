import Bonzai
import SwiftUI

final class HUDNotificationPublisher: ObservableObject {
  @Published var text: String = ""

  init(text: String) {
    self.text = text
  }
}

struct HUDNotificationView: View {
  @ObservedObject var publisher: HUDNotificationPublisher

  init(publisher: HUDNotificationPublisher) {
    self.publisher = publisher
  }

  var body: some View {
    Text(publisher.text)
      .padding()
      .background(
        ZStack {
          ZenVisualEffectView(material: .hudWindow)
            .mask {
              LinearGradient(
                stops: [
                  .init(color: .black, location: 0),
                  .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            }
          ZenVisualEffectView(material: .contentBackground)
            .mask {
              LinearGradient(
                stops: [
                  .init(color: .black.opacity(0.5), location: 0),
                  .init(color: .black, location: 0.75),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            }
        }
      )
  }
}

#Preview {
  HUDNotificationView(publisher: HUDNotificationPublisher(text: "Workflow successful."))
}
