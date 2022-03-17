import Apps
import Combine
import Foundation

final class ApplicationStore: ObservableObject {
  @Published private(set) var applications = [Application]()
  @Published private(set) var dictionary = [String: Application]()
  var subscription: AnyCancellable?

  init() {
    reload()
  }

  func application(for bundleIdentifier: String) -> Application? {
    applications.first(where: { $0.bundleIdentifier == bundleIdentifier })
  }

  func reload() {
    Task(priority: .userInitiated) {
      self.subscription = ApplicationController.asyncLoadApplications()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] applications in
          self?.applications = applications
          var applicationDictionary = [String: Application]()
          for application in applications {
            applicationDictionary[application.bundleIdentifier] = application
          }
          self?.dictionary = applicationDictionary
          self?.subscription = nil
        }
    }
  }
}
