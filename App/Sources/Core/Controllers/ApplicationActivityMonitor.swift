import Cocoa
import Combine
import Foundation

protocol ActivityApplication: Equatable {
  var bundleIdentifier: String { get }
  var isTerminated: Bool { get }
}

extension UserSpace.Application: ActivityApplication {
  var isTerminated: Bool { ref.isTerminated }
}

@MainActor
final class ApplicationActivityMonitor<T: ActivityApplication> {
  // Used for testing.
  var bundleIdentifiers: [String] {
    storage.compactMap(\.bundleIdentifier)
  }

  private var currentApplication: T?
  private var storage: [T] = []
  private var subscription: AnyCancellable?

  init() {}

  func subscribe(to publisher: Published<T>.Publisher) {
    subscription = publisher
      .removeDuplicates()
      .sink { [weak self] application in
        guard let self else { return }

        store(application)
      }
  }

  func previousApplication() -> T? {
    removeTerminatedApplications()

    guard !storage.isEmpty else { return nil }

    let index = max(storage.count - 2, 0)
    return storage[index]
  }

  // MARK: Private methods

  private func store(_ application: T) {
    WindowFocus.frontMostApplicationChanged()
    storage.removeAll(where: { $0.bundleIdentifier == application.bundleIdentifier })
    storage.append(application)
    removeTerminatedApplications()
  }

  private func removeTerminatedApplications() {
    storage.removeAll(where: { $0.isTerminated })
  }
}
