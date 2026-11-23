import AccessibilitySystem
import Carbon
import CoreGraphics
import Foundation
import MachPortSystem

public extension HostInput {
  /// Owns one capture tap. The host checks permissions before starting it.
  @MainActor
  final class CaptureSession {
    public typealias Completion = @MainActor (Result<CapturedElement, any Error>) -> Void
    private let taps: TapSession
    private let capture: @MainActor (CGPoint) async throws -> CapturedElement
    private var sessionID: UUID?
    private var pending: Task<Void, Never>?
    private var capturingClick = false

    public convenience init(signature: Int64) {
      let accessibility = AccessibilitySystem.Client()
      self.init(taps: TapSession(signature: signature)) {
        try await HostInput.captureElement(at: $0, using: accessibility)
      }
    }

    init(taps: TapSession, capture: @escaping @MainActor (CGPoint) async throws -> CapturedElement) {
      self.taps = taps
      self.capture = capture
    }

    public func start(
      onResult: @escaping Completion,
      onDisruption: @escaping TapSession.DisruptionHandler,
      onCancel: @escaping @MainActor () -> Void = {},
    ) throws {
      guard sessionID == nil else { return }

      let id = UUID()
      try taps.startCapture(handler: { [weak self] event in
        guard let self, sessionID == id else { return .passThrough }

        if event.type == .keyDown, event.keyCode == Int64(kVK_Escape) {
          stop()
          onCancel()
          return .passThrough
        }
        switch event.type {
        case .leftMouseDown:
          capturingClick = event.event.flags.contains(.maskCommand)
          return capturingClick ? .suppress : .passThrough
        case .leftMouseDragged:
          return capturingClick ? .suppress : .passThrough
        case .leftMouseUp:
          guard capturingClick else { return .passThrough }

          capturingClick = false
          capture(at: event.event.location, sessionID: id, onResult: onResult)
          return .suppress
        default:
          return .passThrough
        }
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
      capturingClick = false
      pending?.cancel()
      pending = nil
      taps.stopCapture()
    }

    private func capture(at point: CGPoint, sessionID id: UUID, onResult: @escaping Completion) {
      pending?.cancel()
      pending = Task { [weak self, capture] in
        let result: Result<CapturedElement, any Error>
        do {
          guard !Task.isCancelled else { return }

          result = .success(try await capture(point))
        } catch {
          result = .failure(error)
        }
        guard !Task.isCancelled, let self, sessionID == id else { return }

        pending = nil
        onResult(result)
      }
    }
  }
}
