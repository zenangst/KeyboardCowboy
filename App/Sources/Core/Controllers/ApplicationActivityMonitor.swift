import Cocoa
import Combine
import Foundation

@MainActor
final class ApplicationActivityMonitor {
  // Used for testing.
  internal var bundleIdentifiers: [String] {
    storage.map { $0.bundleIdentifier }
  }

  private var currentApplication: UserSpace.Application?
  private var storage: [UserSpace.Application] = []
  private var subscription: AnyCancellable?

  static let shared = ApplicationActivityMonitor()

  init() { }

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    subscription = publisher
      .sink { [weak self] application in
        guard let self else { return }
        self.store(application)
      }
  }

  func previousApplication() -> UserSpace.Application? {
    removeTerminatedApplications()

    guard !storage.isEmpty else { return nil }

    let index = max(storage.count - 2, 0)
    return storage[index]
  }

  // MARK: Private methods

  private func store(_ application: UserSpace.Application) {
    storage.removeAll(where: { $0.bundleIdentifier == application.bundleIdentifier })
    storage.append(application)
    removeTerminatedApplications()
  }

  private func removeTerminatedApplications() {
    storage.removeAll(where: { $0.ref.isTerminated })
  }
}
