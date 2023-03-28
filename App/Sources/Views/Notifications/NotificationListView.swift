import Inject
import SwiftUI

struct NotificationViewModel: Identifiable, Hashable {
  let id: String
  let icon: IconViewModel?
  let name: String
  let result: Result

  enum Result {
    case success
    case failed
  }
}

struct NotificationListView: View {
  @ObservedObject var publisher: ViewModelsPublisher<NotificationViewModel>

  var body: some View {
    VStack(spacing: 0) {
      ForEach(publisher.models) { notification in
        NotificationView(notification: notification)
      }
    }
    .enableInjection()
  }
}

struct NotificationView: View {
  @State private var hasAppeared: Bool = false
  let notification: NotificationViewModel
  var body: some View {
    HStack {
      if let icon = notification.icon {
        IconView(icon: icon, size: .init(width: 24, height: 24))
      }

      Text(notification.name)
        .lineLimit(1)
        .font(.subheadline)
        .frame(minWidth: 200, maxWidth: .infinity, minHeight: 32, alignment: .leading)

      switch notification.result {
      case .success:
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(Color(.systemGreen))
          .background(Color(.systemGreen.blended(withFraction: 0.5, of: NSColor.black)!))
          .mask(Circle())
      case .failed:
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(Color(.systemRed))
          .background(Color(.systemRed.blended(withFraction: 0.5, of: NSColor.black)!))
          .mask(Circle())
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color(.gridColor))
    .cornerRadius(8)
    .padding(1)
    .rotation3DEffect(.degrees(hasAppeared ? 0 : 90), axis: (x: 1, y: 0, z: 0),
                      anchor: .bottom)
    .opacity(hasAppeared ? 1 : 0)
    .scaleEffect(hasAppeared ? 1 : 0.75)
    .animation(.easeOut(duration: 0.25).delay(1), value: hasAppeared)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        hasAppeared = true
      }
    }
  }
}

struct NotificationView_Previews: PreviewProvider {
  static var coordinator = NotificationCoordinator(.init())

  static var previews: some View {
    NotificationListView(publisher: coordinator.publisher)
      .onAppear {
        coordinator.publisher.publish([
          .init(id: UUID().uuidString,
                icon: IconViewModel(bundleIdentifier: "com.apple.Finder",
                                    path: "/System/Library/CoreServices/Finder.app"),
                name: "Finder",
                result: .success),
        ])
      }
      .frame(maxWidth: 300)
  }
}
