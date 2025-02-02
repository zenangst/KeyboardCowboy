import Apps
import AXEssibility
import Combine
import Cocoa
import Foundation
import Windows

@MainActor
final class WindowSpace: WindowSpaceCacheDelegate {
  static let shared = WindowSpace()

  @Published var currentWindow: WindowSpace.Entity?

  private let mapContainer = MapContainer()
  private var cache = WindowSpace.Cache()
  private var observers = [AccessibilityObserver]()
  private var subscriptions: Set<AnyCancellable> = []

  private init() {
    Task { [mapContainer] in
      await cache.setDelegate(self)
      let windows = try WindowsInfo.getWindows(.excludeDesktopElements)
      try? await cache.index(windows, mapContainer: mapContainer)
    }
  }

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    publisher.sink { [weak self] application in
      guard let self else { return }
      self.frontmostApplicationChanged(application)
    }
    .store(in: &subscriptions)
  }

  // MARK: Private methods

  private func frontmostApplicationChanged(_ application: UserSpace.Application) {
    observers.forEach { $0.removeObserver() }
    observers.removeAll()

    let app = AppAccessibilityElement(application.ref.processIdentifier)
    let id = UUID()
    let passthroughPointer = PassthroughPointer(id: id, app: app,
                                                bundleIdentifier: application.bundleIdentifier,
                                                windowSpace: self)
    let pointer = UnsafeMutableRawPointer(Unmanaged.passRetained(passthroughPointer).toOpaque())

    if let focusedWindow = try? app.focusedWindow() {
      updateFocusedWindow(focusedWindow.reference)
    }

    do {
      if let observer = app.observe(.focusedWindowChanged, element: app.reference, id: id, pointer: pointer, callback: { observer, element, _, opaquePointer in
        guard let opaquePointer else { return }
        let pointer = Unmanaged<PassthroughPointer>
          .fromOpaque(opaquePointer)
          .takeUnretainedValue()
        pointer.windowSpace.updateFocusedWindow(element)
      }) {
        observers.append(observer)
      }
    }

    do {
      if let observer = app.observe(.windowCreated, element: app.reference, id: id, pointer: pointer, callback: { observer, element, _, opaquePointer in
        guard let opaquePointer else { return }
        let pointer = Unmanaged<PassthroughPointer>
          .fromOpaque(opaquePointer)
          .takeUnretainedValue()
        pointer.windowSpace
          .cache
          .update(element: element, focused: false, mapContainer: pointer.windowSpace.mapContainer)
      }) {
        observers.append(observer)
      }
    }

    do {
      if let observer = app.observe(.closed, element: app.reference, id: id, pointer: pointer, callback: { observer, element, _, opaquePointer in
        guard let opaquePointer else { return }
        let pointer = Unmanaged<PassthroughPointer>
          .fromOpaque(opaquePointer)
          .takeUnretainedValue()

        guard let windows = try? pointer.app.windows() else { return }

        Task {
          let entities = await windows.asyncCompactMap {
            await $0.convert(with: pointer.windowSpace.mapContainer)
          }
          let bundleIdentifier = pointer.bundleIdentifier
          pointer.windowSpace.cache.update(bundleIdentifier: bundleIdentifier, entities: entities)
        }
      }) {
        passthroughPointer.windowSpace.observers.append(observer)
      }
    }
  }

  private func updateFocusedWindow(_ element: AXUIElement) {
    cache
      .update(element: element, focused: true, mapContainer: mapContainer)
  }

  // MARK: WindowSpaceCacheDelegate

  nonisolated func currentWindowDidChange(_ window: Entity) {
    Task { @MainActor in
      self.currentWindow = window
    }
  }
}

@MainActor
fileprivate final class PassthroughPointer {
  let id: UUID
  let app: AppAccessibilityElement
  let bundleIdentifier: String
  let windowSpace: WindowSpace

  init(id: UUID, app: AppAccessibilityElement, bundleIdentifier: String, windowSpace: WindowSpace) {
    self.id = id
    self.app = app
    self.bundleIdentifier = bundleIdentifier
    self.windowSpace = windowSpace
  }
}
