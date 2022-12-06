import Apps
import Cocoa

final class ApplicationStore: ObservableObject {
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
    // TODO: This search pattern could be improved.
    applications.first(where:  { $0.path.contains((url.path() as NSString).deletingPathExtension) })
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
