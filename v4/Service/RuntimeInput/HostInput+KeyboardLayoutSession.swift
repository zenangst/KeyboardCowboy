import Carbon
import Foundation
import KeyCodeSystem

public extension HostInput {
  /// Owns the current keyboard layout for a host input session. Reading
  /// `layout` is in-memory only; the session does not listen to key events.
  @MainActor
  final class KeyboardLayoutSession {
    static let sourceChanged = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)

    private let center: NotificationCenter
    private let load: @MainActor () throws -> KeyCodeSystem.Layout
    private var observer: (any NSObjectProtocol)?
    public private(set) var layout: KeyCodeSystem.Layout?

    public convenience init() {
      self.init(center: DistributedNotificationCenter.default(), load: KeyCodeSystem.Layout.current)
    }

    init(center: NotificationCenter, load: @escaping @MainActor () throws -> KeyCodeSystem.Layout) {
      self.center = center
      self.load = load
      observer = center
        .addObserver(
          forName: Self.sourceChanged,
          object: nil,
          queue: .main,
        ) { [weak self] _ in
          MainActor.assumeIsolated { self?.refresh() }
        }
      refresh()
    }

    isolated deinit {
      if let observer { center.removeObserver(observer) }
    }

    /// Also available to the host on hardware changes. A failed read
    /// clears the old layout rather than resolving keys against stale data.
    public func refresh() {
      layout = try? load()
    }
  }
}
