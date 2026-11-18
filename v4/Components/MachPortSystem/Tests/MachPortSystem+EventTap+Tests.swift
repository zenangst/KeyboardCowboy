#if DEBUG
import CoreFoundation
import CoreGraphics
@testable import MachPortSystem
import Testing

private final class FakeHandle {
  let context: MachPortSystem.EventTap.Context
  init(_ context: MachPortSystem.EventTap.Context) { self.context = context }
}

@Test func tapLifecycleIsIdempotentAndReloadRemovesBeforeStarting() throws {
  var calls: [String] = []
  let owner = CFRunLoopGetCurrent()
  let mode = CFRunLoopMode.defaultMode!
  let operations = MachPortSystem.EventTap.Operations(
    start: { configuration, loop, context in
      #expect(CFEqual(loop, owner))
      #expect(configuration.runLoopMode == mode)
      calls.append("start")
      return FakeHandle(context)
    },
    stop: { _, loop, actualMode in
      #expect(CFEqual(loop, owner))
      #expect(actualMode == mode)
      calls.append("stop")
    },
  )
  let tap = MachPortSystem.EventTap(
    configuration: .init(runLoopMode: mode),
    syntheticSignature: 42,
    handler: { _ in .passThrough }, operations: operations)
  try tap.start()
  try tap.start()
  try tap.reload()
  tap.stop()
  tap.stop()
  #expect(!tap.isRunning)
  #expect(calls == ["start", "stop", "start", "stop"])
}

@Test func tapCreationAndReloadFailureLeaveItStopped() throws {
  var attempts = 0
  var stops = 0
  let operations = MachPortSystem.EventTap.Operations(start: { _, _, context in
    attempts += 1
    return attempts == 1 ? FakeHandle(context) : nil
  }, stop: { _, _, _ in stops += 1 })
  let tap = MachPortSystem.EventTap(syntheticSignature: 42, handler: { _ in .passThrough }, operations: operations)
  try tap.start()
  #expect(throws: MachPortSystem.EventTap.Failure.creationFailed) { try tap.reload() }
  #expect(!tap.isRunning)
  tap.stop()
  #expect(stops == 1)
  #expect(throws: MachPortSystem.EventTap.Failure.creationFailed) { try tap.start() }
}

@Test func releasingRunningTapTearsItDown() throws {
  var stops = 0
  let operations = MachPortSystem.EventTap.Operations(
    start: { _, _, context in FakeHandle(context) },
    stop: { _, _, _ in stops += 1 },
  )
  var tap: MachPortSystem.EventTap? = .init(
    syntheticSignature: 42, handler: { _ in .passThrough }, operations: operations,
  )
  try tap?.start()
  tap = nil
  #expect(stops == 1)
}

@Test func tapDisruptionAndStoppingDuringDelivery() throws {
  var disruptions: [MachPortSystem.EventTap.Disruption] = []
  var context: MachPortSystem.EventTap.Context?
  var tap: MachPortSystem.EventTap?
  var stops = 0
  let operations = MachPortSystem.EventTap.Operations(start: { _, _, value in
    context = value
    return FakeHandle(value)
  }, stop: { _, _, _ in stops += 1 })
  tap = .init(syntheticSignature: 42, handler: { _ in
    tap?.stop()
    tap = nil
    return .suppress
  }, onDisruption: { disruptions.append($0) }, operations: operations)
  try tap?.start()
  let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 1, keyDown: true))
  #expect(context?.deliver(type: .tapDisabledByTimeout, event: event) === event)
  #expect(context?.deliver(type: .tapDisabledByUserInput, event: event) === event)
  #expect(disruptions == [.timeout, .userInput])
  #expect(context?.deliver(type: .keyDown, event: event) == nil)
  #expect(tap == nil && stops == 1)
}

@Test func callbackResultTransfersOnlyReplacementOwnership() throws {
  let original = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 1, keyDown: true))
  let replacement = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 2, keyDown: true))
  let originalCount = CFGetRetainCount(original)
  let replacementCount = CFGetRetainCount(replacement)
  let unchanged = try #require(MachPortSystem.EventTap.callbackResult(original, original: original))
  #expect(CFGetRetainCount(original) == originalCount)
  #expect(unchanged.takeUnretainedValue() === original)
  let changed = try #require(MachPortSystem.EventTap.callbackResult(replacement, original: original))
  #expect(CFGetRetainCount(replacement) == replacementCount + 1)
  #expect(changed.takeRetainedValue() === replacement)
  #expect(CFGetRetainCount(replacement) == replacementCount)
  #expect(MachPortSystem.EventTap.callbackResult(nil, original: original) == nil)
}

@Test func listenOnlyTapIsRejectedBeforeInstallation() {
  var attempted = false
  let operations = MachPortSystem.EventTap.Operations(
    start: { _, _, context in
      attempted = true
      return FakeHandle(context)
    },
    stop: { _, _, _ in },
  )
  let tap = MachPortSystem.EventTap(
    configuration: .init(options: .listenOnly),
    syntheticSignature: 42,
    handler: { _ in .passThrough },
    operations: operations,
  )
  #expect(throws: MachPortSystem.EventTap.Failure.unsupportedTapOptions) {
    try tap.start()
  }
  #expect(!attempted)
  #expect(!tap.isRunning)
}
#endif
