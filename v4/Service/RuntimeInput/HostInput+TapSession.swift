import CoreGraphics
import MachPortSystem

public extension HostInput {
  /// The service owns a session on the main run loop. It starts listening only
  /// after the host has checked permissions and supplied its routing policy.
  @MainActor
  final class TapSession {
    public typealias Handler = @MainActor (MachPortSystem.InterceptedEvent) -> MachPortSystem.EventDisposition
    public typealias DisruptionHandler = @MainActor (MachPortSystem.EventTap.Disruption) -> Void
    typealias MakeTap = @MainActor (
      MachPortSystem.TapConfiguration,
      Int64,
      @escaping Handler,
      @escaping DisruptionHandler,
    ) -> Tap

    private let signature: Int64
    private let makeTap: MakeTap
    private var keyboard: Tap?
    private var capture: Tap?
    public private(set) var keyboardPoster: MachPortSystem.KeyboardEventPoster?

    public convenience init(signature: Int64) {
      self.init(signature: signature) { configuration, signature, handler, disruption in
        let tap = MachPortSystem.EventTap(
          configuration: configuration,
          syntheticSignature: signature,
          handler: { event in
            var disposition = MachPortSystem.EventDisposition.passThrough
            MainActor.assumeIsolated { disposition = handler(event) }
            return disposition
          },
          onDisruption: { reason in MainActor.assumeIsolated { disruption(reason) } },
        )
        return Tap(
          start: tap.start, stop: tap.stop, reload: tap.reload,
          makePoster: tap.makeKeyboardEventPoster,
        )
      }
    }

    init(signature: Int64, makeTap: @escaping MakeTap) {
      self.signature = signature
      self.makeTap = makeTap
    }

    /// Disruption clears host state synchronously; recovery runs as a separate
    /// host decision after the callback returns.
    public func startKeyboard(
      onFlags: @escaping Handler,
      onEvent: @escaping Handler,
      onDisruption: @escaping DisruptionHandler,
    ) throws {
      guard keyboard == nil else { return }

      let tap = makeTap(.init(), signature, { event in
        event.type == .flagsChanged ? onFlags(event) : onEvent(event)
      }, onDisruption)
      let poster = try tap.makePoster()
      try tap.start()
      keyboard = tap
      keyboardPoster = poster
    }

    public func reloadKeyboard() throws {
      guard let keyboard else { return }

      do {
        try keyboard.reload()
      } catch {
        stopKeyboard()
        throw error
      }
    }

    public func stopKeyboard() {
      keyboard?.stop()
      keyboard = nil
      keyboardPoster = nil
    }

    public func startCapture(
      handler: @escaping Handler,
      onDisruption: @escaping DisruptionHandler,
    ) throws {
      let mask = MachPortSystem.TapConfiguration.keyboardEventMask
        | (1 << CGEventType.leftMouseDown.rawValue)
        | (1 << CGEventType.leftMouseUp.rawValue)
        | (1 << CGEventType.leftMouseDragged.rawValue)
      try startCapture(eventMask: mask, handler: handler, onDisruption: onDisruption)
    }

    func startCapture(
      eventMask: CGEventMask, handler: @escaping Handler, onDisruption: @escaping DisruptionHandler,
    ) throws {
      guard capture == nil else { return }

      let tap = makeTap(.init(eventMask: eventMask), signature, handler, onDisruption)
      try tap.start()
      capture = tap
    }

    public func stopCapture() {
      capture?.stop()
      capture = nil
    }
  }
}
