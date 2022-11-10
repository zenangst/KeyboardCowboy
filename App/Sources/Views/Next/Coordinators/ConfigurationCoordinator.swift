import SwiftUI

final class ConfigurationCoordinator {
  let configurationPublisher: ConfigurationPublisher

  init() {
    self.configurationPublisher = DesignTime.configurationPublisher
  }
}
