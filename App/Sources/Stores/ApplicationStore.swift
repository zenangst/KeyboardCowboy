import Apps
import Cocoa

final class ApplicationStore: ObservableObject {
  private(set) var applicationsByPath = [String: Application]()
  @Published private(set) var applications = [Application]()
  @Published private(set) var dictionary = [String: Application]()

  init() {
    reload()
  }

  func applicationsToOpen(_ path: String) -> [Application] {
    guard let url = URL(string: path) else { return [] }
    return NSWorkspace.shared.urlsForApplications(toOpen: url)
      .compactMap { application(at: $0) }
  }

  func application(at url: URL) -> Application? {
    let path = String(url.path(percentEncoded: false).dropLast())
    let application  = applicationsByPath[path]
    return application
  }

  func application(for bundleIdentifier: String) -> Application? {
    dictionary[bundleIdentifier]
  }

  func reload() {
    Task(priority: .userInitiated) {
      let newApplications = await ApplicationController.load()
      var applicationDictionary = [String: Application]()
      var applicationsByPath = [String: Application]()
      for application in newApplications {
        applicationDictionary[application.bundleIdentifier] = application
        applicationsByPath[application.path] = application
      }

      await MainActor.run { [applicationDictionary, applicationsByPath] in
        self.applications = newApplications
        self.dictionary = applicationDictionary
        self.applicationsByPath = applicationsByPath
      }
    }
  }
}
