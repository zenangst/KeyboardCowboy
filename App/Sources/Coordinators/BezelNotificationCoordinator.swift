import SwiftUI

@MainActor
public final class BezelNotificationCoordinator {
  let publisher = BezelNotificationPublisher(.init(text: ""))

  func publish(_ notification: BezelNotificationViewModel) {
    publisher.publish(notification)
  }
}
