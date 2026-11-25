import ApplicationServices
import Foundation

public extension AccessibilitySystem {
  enum WindowEvent: CaseIterable, Sendable {
    case created, focusChanged, elementDestroyed

    fileprivate var notification: String {
      switch self {
      case .created: kAXWindowCreatedNotification
      case .focusChanged: kAXFocusedWindowChangedNotification
      case .elementDestroyed: kAXUIElementDestroyedNotification
      }
    }
  }

  /// Observes one application on the main run loop. Events invalidate an
  /// inventory; they don't identify individual windows or maintain a cache.
  @MainActor
  final class WindowObservation {
    private let makeRegistration: @MainActor (
      Int32, @escaping @MainActor (WindowEvent) -> Void,
    ) throws -> any WindowRegistration
    private var registration: (any WindowRegistration)?
    private var generation: UUID?

    public convenience init() {
      self.init(makeRegistration: { try NativeWindowRegistration(pid: $0, receive: $1) })
    }

    init(makeRegistration: @escaping @MainActor (
      Int32, @escaping @MainActor (WindowEvent) -> Void,
    ) throws -> any WindowRegistration) {
      self.makeRegistration = makeRegistration
    }

    /// Replaces the previous observation. If registration fails, nothing is
    /// left observing. Call stop when the host detects app exit or trust loss.
    public func start(
      processIdentifier pid: Int32,
      receive: @escaping @MainActor (WindowEvent) -> Void,
    ) throws {
      stop()
      let token = UUID()
      let pending = try makeRegistration(pid) { [weak self] event in
        guard self?.generation == token else { return }

        receive(event)
      }
      do {
        for event in WindowEvent.allCases { try pending.add(event) }
      } catch {
        pending.stop()
        throw error
      }
      registration = pending
      generation = token
      pending.install()
    }

    public func stop() {
      generation = nil
      let previous = registration
      registration = nil
      previous?.stop()
    }

    isolated deinit { stop() }
  }
}

extension AccessibilitySystem {
  @MainActor
  protocol WindowRegistration: AnyObject {
    func add(_ event: WindowEvent) throws
    func install()
    func stop()
  }

  @MainActor
  private final class NativeWindowRegistration: WindowRegistration {
    private let application: AXUIElement
    private let receive: @MainActor (WindowEvent) -> Void
    private var observer: AXObserver?

    init(pid: Int32, receive: @escaping @MainActor (WindowEvent) -> Void) throws {
      guard pid > 0 else { throw Failure(.invalidConfiguration, operation: "AXObserverCreate(pid)") }

      application = AXUIElementCreateApplication(pid)
      self.receive = receive
      var observer: AXObserver?
      try Self.check(AXObserverCreate(pid, { _, _, notification, context in
        guard let context else { return }

        let registration = Unmanaged<NativeWindowRegistration>.fromOpaque(context).takeUnretainedValue()
        let name = notification as String
        MainActor.assumeIsolated {
          if let event = WindowEvent.allCases.first(where: { $0.notification == name }) {
            withExtendedLifetime(registration) { registration.receive(event) }
          }
        }
      }, &observer), operation: "AXObserverCreate")
      guard let observer else { throw Failure(.malformedValue, operation: "AXObserverCreate") }

      self.observer = observer
    }

    func add(_ event: WindowEvent) throws {
      guard let observer else { throw Failure(.expiredScope, operation: "AXObserverAddNotification") }

      try Self.check(AXObserverAddNotification(
        observer, application, event.notification as CFString, Unmanaged.passUnretained(self).toOpaque(),
      ), operation: "AXObserverAddNotification(\(event.notification))")
    }

    func install() {
      guard let observer else { return }

      CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
    }

    func stop() {
      guard let observer else { return }

      let source = AXObserverGetRunLoopSource(observer)
      CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
      CFRunLoopSourceInvalidate(source)
      // Releasing the observer discards all registrations, including a partial
      // setup. No further callbacks can use the context after invalidation.
      self.observer = nil
    }

    private static func check(_ status: AXError, operation: String) throws {
      guard status != .success else { return }

      let kind: Failure.Kind = switch status {
      case .apiDisabled: .apiDisabled
      case .cannotComplete: .cannotComplete
      case .invalidUIElement: .invalidElement
      case .notificationUnsupported: .notificationUnsupported
      default: .other
      }
      throw Failure(kind, operation: operation, rawAXStatus: status.rawValue)
    }
  }
}
