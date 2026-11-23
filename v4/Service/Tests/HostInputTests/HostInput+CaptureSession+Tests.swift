import Carbon
import CoreGraphics
@testable import HostInput
import MachPortSystem
import Testing

@MainActor
@Test func captureSessionRoutesCommandClickAndStopsOnEscape() async throws {
  var route: HostInput.TapSession.Handler?
  var stops = 0
  var cancellations = 0
  let taps = HostInput.TapSession(signature: 42) { _, signature, handler, _ in
    route = handler
    return .init(start: {}, stop: { stops += 1 }, reload: {},
                 makePoster: { .init(eventSource: nil, syntheticSignature: signature) })
  }
  let point = CGPoint(x: -30, y: 40)
  let session = HostInput.CaptureSession(taps: taps) {
    #expect($0 == point)
    return .init(role: .button, frame: CGRect(origin: point, size: CGSize(width: 20, height: 10)))
  }
  let (results, result) = AsyncStream<HostInput.CapturedElement>.makeStream()
  try session.start(onResult: {
    if case .success(let captured) = $0 { result.yield(captured) }
    result.finish()
  }, onDisruption: { _ in Issue.record("Unexpected disruption") },
  onCancel: { cancellations += 1 })

  let handler = try #require(route)
  let router = MachPortSystem.EventRouter(syntheticSignature: 42)
  let down = try #require(CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                                  mouseCursorPosition: point, mouseButton: .left))
  let up = try #require(CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                                mouseCursorPosition: point, mouseButton: .left))
  down.flags = []
  #expect(router.route(down, type: .leftMouseDown, handler: handler) === down)
  down.flags = .maskCommand
  up.flags = []
  #expect(router.route(down, type: .leftMouseDown, handler: handler) == nil)
  #expect(router.route(up, type: .leftMouseUp, handler: handler) == nil)
  var iterator = results.makeAsyncIterator()
  let captured = await iterator.next()
  #expect(captured?.role == .button)

  let escape = try #require(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Escape), keyDown: true))
  #expect(router.route(escape, type: .keyDown, handler: handler) === escape)
  session.stop()
  #expect(stops == 1)
  #expect(cancellations == 1)
  #expect(router.route(down, type: .leftMouseDown, handler: handler) === down)
}
