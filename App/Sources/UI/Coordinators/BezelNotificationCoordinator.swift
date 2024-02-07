import SwiftUI

@MainActor
public final class BezelNotificationCoordinator {
  let publisher = BezelNotificationPublisher(.init(id: UUID().uuidString, text: ""))

  init() {}

  func publish(_ notification: BezelNotificationViewModel) {
    publisher.publish(notification)
  }
}
