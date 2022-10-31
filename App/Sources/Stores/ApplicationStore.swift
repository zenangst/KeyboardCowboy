import Apps
import Foundation

final class ApplicationStore: ObservableObject {
  @Published private(set) var applications = [Application]()
  @Published private(set) var dictionary = [String: Application]()

  init() {
    reload()
  }

  func application(for bundleIdentifier: String) -> Application? {
    applications.first(where: { $0.bundleIdentifier == bundleIdentifier })
  }

  func reload() {
    Task(priority: .userInitiated) {
      let newApplications = await ApplicationController.load()
      var applicationDictionary = [String: Application]()
      for application in newApplications {
        applicationDictionary[application.bundleIdentifier] = application
      }

      await MainActor.run { [applicationDictionary] in
        self.applications = newApplications
        self.dictionary = applicationDictionary
      }
    }
  }
}
