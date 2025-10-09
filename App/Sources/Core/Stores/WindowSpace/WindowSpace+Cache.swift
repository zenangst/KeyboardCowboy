import ApplicationServices
import AXEssibility
import Windows

protocol WindowSpaceCacheDelegate {
  func currentWindowDidChange(_ window: WindowSpace.Entity)
}

extension WindowSpace {
  actor Cache {
    static let debug: Bool = true

    typealias BundleIdentifier = String

    var delegate: WindowSpaceCacheDelegate?

    private var current: WindowSpace.Entity?
    private var storage: [BundleIdentifier: [WindowSpace.Entity.ID: WindowSpace.Entity]] = [:]

    init() {}

    func index(_ windows: [WindowModel], mapContainer: WindowSpace.MapContainer) async throws {
      await withTaskGroup(of: WindowSpace.Entity?.self) { [mapContainer] group in
        for window in windows {
          group.addTask {
            await window.convert(mapContainer)
          }
        }

        for await case let .some(result) in group {
          if var currentEntry = storage[result.bundleIdentifier] {
            currentEntry[result.id] = result
            storage[result.bundleIdentifier] = currentEntry
          } else {
            storage[result.bundleIdentifier] = [result.id: result]
          }
        }
      }
    }

    func setDelegate(_ delegate: WindowSpaceCacheDelegate) {
      self.delegate = delegate
    }

    func windows(for bundleIdentifier: BundleIdentifier) -> [WindowSpace.Entity] {
      if let application = storage[bundleIdentifier] {
        return Array(application.values)
      }

      return []
    }

    nonisolated func update(element: AXUIElement, focused: Bool, mapContainer: WindowSpace.MapContainer) {
      Task { [weak self, mapContainer] in
        guard let self, let entity = await WindowAccessibilityElement(element)?
          .convert(with: mapContainer)
        else {
          return
        }

        await addOrUpdateCache(entity)

        if focused {
          await setCurrent(entity)
        }
      }
    }

    nonisolated func remove(bundleIdentifier: String) {
      Task { await removeBundleIdentifier(bundleIdentifier) }
    }

    nonisolated func update(bundleIdentifier: String, entities: [WindowSpace.Entity]) {
      Task { await updateBundleIdentifier(bundleIdentifier, entities: entities) }
    }

    // MARK: Private methods

    private func setCurrent(_ entity: WindowSpace.Entity) {
      current = entity
      delegate?.currentWindowDidChange(entity)
    }

    private func addOrUpdateCache(_ entity: WindowSpace.Entity) {
      if var currentEntry = storage[entity.bundleIdentifier] {
        currentEntry[entity.id] = entity
        storage[entity.bundleIdentifier] = currentEntry
      } else {
        storage[entity.bundleIdentifier] = [entity.id: entity]
      }
    }

    private func updateBundleIdentifier(_ bundleIdentifier: String, entities: [WindowSpace.Entity]) {
      storage[bundleIdentifier] = entities.reduce(into: [:]) { result, entity in
        result[entity.id] = entity
      }
    }

    private func removeBundleIdentifier(_ bundleIdentifier: String) {
      storage.removeValue(forKey: bundleIdentifier)
    }

    func debug() {
      guard Self.debug else { return }

      for (bundleIdentifier, windows) in storage {
        print("\(bundleIdentifier)")
        for (_, window) in windows {
          print("  \(window.id)")
        }
      }

      print("--------------------")
    }
  }
}
