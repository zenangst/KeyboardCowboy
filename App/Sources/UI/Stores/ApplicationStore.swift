import Apps
import Combine
import Cocoa

final class ApplicationStore: ObservableObject, @unchecked Sendable {
  static let domain: String = "ApplicationStore"

  private var fileWatchers = [FileWatcher]()
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
        Task { await self.reload(AppStorageContainer.shared.additionalApplicationPaths) }
      }
  }

  func apps() -> [Application] {
    self.applications
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

  func load() async {
    Benchmark.shared.start("ApplicationController.load")
    let decoder = JSONDecoder()
    let additionalPaths = await AppStorageContainer.shared.additionalApplicationPaths
    if let newApplications: [Application] = try? AppCache.load(Self.domain, name: "applications.json", decoder: decoder) {
      do {
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

        Task.detached { [weak self] in
          await self?.reload(additionalPaths)
        }
      }
    } else {
      await reload(additionalPaths)
    }
    Benchmark.shared.stop("ApplicationController.load")
  }

  // MARK: - Private methods

  private func reload(_ additionalPaths: [String]) async {
    Benchmark.shared.start("ApplicationController.reload")
    let additionalDirectories = additionalPaths.map {
      URL(filePath: $0)
    }
    let newApplications = await ApplicationController.load(additionalDirectories)
    Benchmark.shared.stop("ApplicationController.reload")

    if applications != newApplications {
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

    do {
      try AppCache.entry(Self.domain, name: "applications.json").write(applications)

      var monitorPaths: [URL] = additionalDirectories
      monitorPaths.append(URL(filePath: ("~/Applications" as NSString).expandingTildeInPath))
      monitorPaths.append(URL(filePath: ("/Applications" as NSString).expandingTildeInPath))

      fileWatchers.forEach { $0.stop() }
      var newWatchers = [FileWatcher]()
      for path in monitorPaths {
        if let fileWatcher = try? FileWatcher(path, handler: { [weak self] url in
          self?.passthrough.send(())
        }) {
          newWatchers.append(fileWatcher)
          fileWatcher.start()
        }
      }
      fileWatchers = newWatchers
    } catch let error {
      print(error)
    }
  }
}
