import CoreGraphics
import CowboyCore

extension Application {
  /// The host supplies every effect and must share one instance across stage operations.
  /// No Stage Manager setting or permission checks are performed here.
  public actor StageOrchestrator {
    public struct Window: Sendable {
      public let id: UInt32
      public let frame: CGRect
      public init(id: UInt32, frame: CGRect) { self.id = id; self.frame = frame }
    }

    public struct Snapshot: Sendable {
      /// Opaque host identifier for the application whose focus should be restored.
      public let frontmost: String?
      /// Only windows visible in the current Space should be supplied.
      public let windows: [Window]
      /// Global-coordinate frame of the screen containing the thumbnail.
      public let screen: CGRect
      public init(frontmost: String?, windows: [Window], screen: CGRect) {
        self.frontmost = frontmost; self.windows = windows; self.screen = screen
      }
    }

    public struct Target: Sendable {
      public let hidden: Bool
      public init(hidden: Bool) { self.hidden = hidden }
    }

    /// Effects must cooperate with cancellation and bound their own individual calls.
    public struct Effects: Sendable {
      public var snapshot: @Sendable () async throws -> Snapshot
      /// Returns nil until the target is running and finished launching.
      public var target: @Sendable (Command.Application) async throws -> Target?
      public var activateTarget: @Sendable (Command.Application) async throws -> Void
      /// Cleanup callbacks must be usable even when the calling task is cancelled.
      public var restoreFocus: @Sendable (String) async throws -> Void
      public var unhide: @Sendable (Command.Application) async throws -> Void
      /// Throw `.accessibilityTemporarilyUnavailable` only for retryable readiness failures.
      public var accessibilityWindows: @Sendable (Command.Application) async throws -> [Window]
      public var pointer: @Sendable () async throws -> CGPoint
      /// Must also restore the pointer when called from a cancelled task.
      public var movePointer: @Sendable (CGPoint) async throws -> Void
      public var shiftClick: @Sendable (CGPoint) async throws -> Void
      public var unminimizeAndRaise: @Sendable (UInt32) async throws -> Void
      public var sleep: @Sendable (Duration) async throws -> Void

      public init(snapshot: @escaping @Sendable () async throws -> Snapshot,
                  target: @escaping @Sendable (Command.Application) async throws -> Target?,
                  activateTarget: @escaping @Sendable (Command.Application) async throws -> Void,
                  restoreFocus: @escaping @Sendable (String) async throws -> Void,
                  unhide: @escaping @Sendable (Command.Application) async throws -> Void,
                  accessibilityWindows: @escaping @Sendable (Command.Application) async throws -> [Window],
                  pointer: @escaping @Sendable () async throws -> CGPoint,
                  movePointer: @escaping @Sendable (CGPoint) async throws -> Void,
                  shiftClick: @escaping @Sendable (CGPoint) async throws -> Void,
                  unminimizeAndRaise: @escaping @Sendable (UInt32) async throws -> Void,
                  sleep: @escaping @Sendable (Duration) async throws -> Void) {
        self.snapshot = snapshot; self.target = target; self.activateTarget = activateTarget
        self.restoreFocus = restoreFocus; self.unhide = unhide; self.accessibilityWindows = accessibilityWindows
        self.pointer = pointer; self.movePointer = movePointer; self.shiftClick = shiftClick
        self.unminimizeAndRaise = unminimizeAndRaise; self.sleep = sleep
      }
    }

    public enum Failure: Error, Equatable {
      case timedOut, windowDisappeared, windowNotVisible, alreadyRunning, accessibilityTemporarilyUnavailable
    }
    private let effects: Effects
    private let launchAttempts: Int
    private let unhideAttempts: Int
    private let windowAttempts: Int
    private let interval: Duration
    private var isRunning = false
    public init(effects: Effects, attempts: Int? = nil, interval: Duration = .milliseconds(100)) {
      self.effects = effects
      self.launchAttempts = max(1, attempts ?? 50)
      self.unhideAttempts = max(1, attempts ?? 10)
      self.windowAttempts = max(1, attempts ?? 20)
      self.interval = interval
    }

    /// Returns false for an already-in-stage or unmatched window, allowing ordinary
    /// opening. Timeouts and effect failures throw; cancellation never triggers fallback.
    public func execute(_ command: Command.Application) async throws -> Bool {
      try Task.checkCancellation()
      guard !isRunning else { throw Failure.alreadyRunning }
      isRunning = true
      defer { isRunning = false }
      var snapshot = try await perform { try await effects.snapshot() }
      var target = try await perform { try await effects.target(command) }
      if target == nil {
        try await activateAndRestore(command, focus: snapshot.frontmost)
        do {
          target = try await poll(attempts: launchAttempts) { try await effects.target(command) }
        } catch {
          if let focus = snapshot.frontmost { try? await effects.restoreFocus(focus) }
          try Task.checkCancellation()
          throw error
        }
        if let focus = snapshot.frontmost { try await perform { try await effects.restoreFocus(focus) } }
        try Task.checkCancellation()
        snapshot = try await perform { try await effects.snapshot() }
      }
      guard let target else { throw Failure.timedOut }
      if target.hidden {
        try Task.checkCancellation()
        try await perform { try await effects.unhide(command) }
        _ = try await poll(attempts: unhideAttempts) {
          guard let current = try await effects.target(command), !current.hidden else { return nil as Target? }
          return current
        }
        try Task.checkCancellation()
        snapshot = try await perform { try await effects.snapshot() }
      }
      try Task.checkCancellation()
      var accessibilityWindows = try await eligibleWindows(command)
      try Task.checkCancellation()
      if accessibilityWindows.isEmpty {
        try await activateAndRestore(command, focus: snapshot.frontmost)
        do {
          accessibilityWindows = try await poll(attempts: windowAttempts) {
            let windows = try await eligibleWindows(command)
            return windows.isEmpty ? nil : windows
          }
        } catch {
          if let focus = snapshot.frontmost { try? await effects.restoreFocus(focus) }
          try Task.checkCancellation()
          throw error
        }
        if let focus = snapshot.frontmost { try await perform { try await effects.restoreFocus(focus) } }
        try Task.checkCancellation()
        try await perform { try await effects.sleep(.seconds(1)) }
        try Task.checkCancellation()
        snapshot = try await perform { try await effects.snapshot() }
      }
      var matching = matchedWindows(accessibilityWindows, in: snapshot)
      if matching.isEmpty {
        for index in 0..<windowAttempts {
          if index > 0 { try await perform { try await effects.sleep(interval) } }
          accessibilityWindows = try await eligibleWindows(command)
          snapshot = try await perform { try await effects.snapshot() }
          matching = matchedWindows(accessibilityWindows, in: snapshot)
          if !matching.isEmpty { break }
        }
      }
      guard let match = matching.first(where: { $0.ax.frame != $0.visible.frame }) else { return false }
      let ax = match.ax
      var window = match.visible
      guard snapshot.screen.width >= 1, snapshot.screen.height >= 1,
            snapshot.screen.minX.isFinite, snapshot.screen.maxX.isFinite,
            snapshot.screen.minY.isFinite, snapshot.screen.maxY.isFinite else {
        throw Failure.windowNotVisible
      }
      try Task.checkCancellation()
      let original = try await perform { try await effects.pointer() }
      do {
        try Task.checkCancellation()
        if window.frame.minX < snapshot.screen.minX || window.frame.maxX > snapshot.screen.maxX {
          let x = window.frame.minX < snapshot.screen.minX ? snapshot.screen.minX : max(snapshot.screen.minX, snapshot.screen.maxX - 1)
          let y = min(max(window.frame.midY, snapshot.screen.minY), snapshot.screen.maxY - 1)
          try await perform { try await effects.movePointer(CGPoint(x: x, y: y)) }
          try Task.checkCancellation()
          try await perform { try await effects.sleep(.milliseconds(175)) }
          try Task.checkCancellation()
          snapshot = try await perform { try await effects.snapshot() }
          guard let refreshed = snapshot.windows.first(where: { $0.id == ax.id }) else { throw Failure.windowDisappeared }
          window = refreshed
        }
        let visible = window.frame.intersection(snapshot.screen)
        guard !visible.isNull, visible.width > 0, visible.height > 0 else { throw Failure.windowNotVisible }
        let click = CGPoint(x: visible.minX + min(12, visible.width / 2), y: visible.midY)
        try Task.checkCancellation()
        try await perform { try await effects.shiftClick(click) }
        try Task.checkCancellation()
        try await perform { try await effects.unminimizeAndRaise(ax.id) }
        try Task.checkCancellation()
      } catch {
        try? await effects.movePointer(original)
        try Task.checkCancellation()
        throw error
      }
      try await effects.movePointer(original)
      try Task.checkCancellation()
      return true
    }

    private func activateAndRestore(_ command: Command.Application, focus: String?) async throws {
      try Task.checkCancellation()
      do {
        try await perform { try await effects.activateTarget(command) }
        try Task.checkCancellation()
      } catch {
        if let focus { try? await effects.restoreFocus(focus) }
        try Task.checkCancellation()
        throw error
      }
      if let focus { try await perform { try await effects.restoreFocus(focus) } }
      try Task.checkCancellation()
    }

    private func eligibleWindows(_ command: Command.Application) async throws -> [Window] {
      do {
        return try await perform { try await effects.accessibilityWindows(command) }.filter { $0.frame.height > 20 }
      } catch Failure.accessibilityTemporarilyUnavailable {
        try Task.checkCancellation()
        return []
      }
    }

    private func matchedWindows(_ windows: [Window], in snapshot: Snapshot) -> [(ax: Window, visible: Window)] {
      windows.compactMap { ax in
        snapshot.windows.first(where: { $0.id == ax.id }).map { (ax: ax, visible: $0) }
      }
    }

    private func poll<T: Sendable>(attempts: Int, _ read: () async throws -> T?) async throws -> T {
      for index in 0..<attempts {
        try Task.checkCancellation()
        let value = try await perform(read)
        try Task.checkCancellation()
        if let value { return value }
        if index + 1 < attempts {
          try await perform { try await effects.sleep(interval) }
        }
      }
      throw Failure.timedOut
    }

    private func perform<T: Sendable>(_ effect: () async throws -> T) async throws -> T {
      try Task.checkCancellation()
      do {
        let value = try await effect()
        try Task.checkCancellation()
        return value
      } catch {
        try Task.checkCancellation()
        throw error
      }
    }
  }
}
