import Apps
import Combine
import Cocoa

final class ApplicationStore: ObservableObject {
  static var appStorage: AppStorageStore = .init()
  private var passthrough = PassthroughSubject<Void, Never>()
  private var subscription: AnyCancellable?
  private(set) var applicationsByPath = [String: Application]()
  @Published private(set) var applications = [Application]()
  @Published private(set) var dictionary = [String: Application]()

  static let shared = ApplicationStore()

  private init() {
    subscription = passthrough
      .debounce(for: 1.0, scheduler: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self else { return }
        Task { await self.reload() }
      }
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

  func reload() async {
    Benchmark.start("ApplicationController.load")
    let newApplications = await ApplicationController.load(
      Self.appStorage.additionalApplicationPaths.map { URL(filePath: $0) }
    )
    Benchmark.finish("ApplicationController.load")
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
