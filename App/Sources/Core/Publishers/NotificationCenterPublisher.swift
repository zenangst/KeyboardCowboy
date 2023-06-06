import Cocoa
import Combine

final class NotificationCenterPublisher {
  @Published private(set) var keyboardSelectionDidChange: UUID?

  private var keyboardSelectionDidChangeSubscription: AnyCancellable?

  init(_ notificationCenter: NotificationCenter = .default) {
    keyboardSelectionDidChangeSubscription = notificationCenter
      .publisher(for: NSTextInputContext.keyboardSelectionDidChangeNotification)
      .sink { [weak self] _ in
        self?.keyboardSelectionDidChange = UUID()
      }
  }
}
