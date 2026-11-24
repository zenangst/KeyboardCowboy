import Carbon
import CoreGraphics
import Foundation
import KeyboardFeature

public extension HostInput {
  /// Captures one shortcut without suppressing events. The host checks
  /// permissions and stops the session when the recording UI closes.
  @MainActor
  final class ShortcutRecordingSession {
    private let taps: TapSession
    private let layouts: KeyboardLayoutSession
    private var sessionID: UUID?

    public convenience init(signature: Int64, layouts: KeyboardLayoutSession) {
      self.init(taps: TapSession(signature: signature), layouts: layouts)
    }

    init(taps: TapSession, layouts: KeyboardLayoutSession) {
      self.taps = taps
      self.layouts = layouts
    }

    /// Unmodified Escape cancels. Repeats and unresolved keys are ignored.
    public func start(
      onShortcut: @escaping @MainActor (Keyboard.Shortcut) -> Void,
      onDisruption: @escaping TapSession.DisruptionHandler,
      onCancel: @escaping @MainActor () -> Void = {},
    ) throws {
      guard sessionID == nil else { return }

      let id = UUID()
      try taps.startCapture(eventMask: 1 << CGEventType.keyDown.rawValue, handler: { [weak self] event in
        guard let self, sessionID == id, event.type == .keyDown,
              !event.isRepeat else { return .passThrough }

        let flags = event.event.flags
        let modifiers: CGEventFlags = [
          .maskShift,
          .maskControl,
          .maskAlternate,
          .maskCommand,
          .maskSecondaryFn,
          .maskAlphaShift,
        ]

        if event.keyCode == Int64(kVK_Escape), flags.isDisjoint(with: modifiers) {
          stop()
          onCancel()
        } else if let shortcut = HostInput.captureShortcut(from: event.snapshot(), layouts: layouts) {
          stop()
          onShortcut(shortcut)
        }

        return .passThrough
      }, onDisruption: { [weak self] reason in
        guard let self, sessionID == id else { return }

        stop()
        onDisruption(reason)
      })
      sessionID = id
    }

    public func stop() {
      guard sessionID != nil else { return }

      sessionID = nil
      taps.stopCapture()
    }

    isolated deinit { stop() }
  }
}
