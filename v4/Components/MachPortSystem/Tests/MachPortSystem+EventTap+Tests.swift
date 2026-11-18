#if DEBUG
import CoreFoundation
import CoreGraphics
import Foundation
@testable import MachPortSystem
import Testing

private final class FakeHandle {
  let context: MachPortSystem.EventTap.Context
  init(_ context: MachPortSystem.EventTap.Context) { self.context = context }
}

@Test func typedHandleRetainsConcreteHandleAndContext() throws {
  weak var retainedHandle: FakeHandle?
  weak var retainedContext: MachPortSystem.EventTap.Context?
  var stopped = false
  let operations = MachPortSystem.EventTap.Operations(
    start: { _, _, context -> FakeHandle? in
      let handle = FakeHandle(context)
      retainedHandle = handle
      return handle
    },
    stop: { handle, _, _ in
      #expect(handle === retainedHandle)
      #expect(handle.context === retainedContext)
      stopped = true
    },
    isEnabled: { handle in handle === retainedHandle },
  )
  var handle: MachPortSystem.EventTap.Handle?
  do {
    let context = MachPortSystem.EventTap.Context(
      configuration: .init(), signature: 42,
      handler: { _ in .passThrough }, onDisruption: { _ in },
    )
    retainedContext = context
    handle = operations.start(.init(), CFRunLoopGetCurrent(), context)
  }
  let installed = try #require(handle)
  #expect(retainedHandle != nil && retainedContext != nil)
  #expect(operations.isEnabled(installed))
  operations.stop(installed, CFRunLoopGetCurrent(), .defaultMode)
  #expect(stopped)
  handle = nil
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

@Test func enabledStateReflectsInstalledTapAndHostRecovery() throws {
  var enabled = true
  var context: MachPortSystem.EventTap.Context?
  let operations = MachPortSystem.EventTap.Operations(
    start: { _, _, value in
      context = value
      enabled = true
      return FakeHandle(value)
    },
    stop: { _, _, _ in enabled = false },
    isEnabled: { _ in enabled },
  )
  var disruptions: [MachPortSystem.EventTap.Disruption] = []
  let tap = MachPortSystem.EventTap(
    syntheticSignature: 42,
    handler: { _ in .passThrough },
    onDisruption: { disruptions.append($0) },
    operations: operations,
  )
  #expect(!tap.isRunning && !tap.isEnabled)
  try tap.start()
  #expect(tap.isRunning && tap.isEnabled)
  enabled = false
  let event = try #require(CGEvent(source: nil))
  _ = context?.deliver(type: .tapDisabledByTimeout, event: event)
  #expect(disruptions == [.timeout])
  #expect(tap.isRunning && !tap.isEnabled)
  try tap.reload()
  #expect(tap.isRunning && tap.isEnabled)
  tap.stop()
  #expect(!tap.isRunning && !tap.isEnabled)
}

@Test func disruptionResetsHeldEventIdentity() throws {
  var ids: [UUID] = []
  let context = MachPortSystem.EventTap.Context(
    configuration: .init(),
    signature: 42,
    handler: { event in
      ids.append(event.id)
      return .passThrough
    },
    onDisruption: { _ in },
  )
  let down = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 1, keyDown: true))
  let up = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 1, keyDown: false))
  _ = context.deliver(type: .keyDown, event: down)
  _ = context.deliver(type: .tapDisabledByTimeout, event: down)
  _ = context.deliver(type: .keyUp, event: up)
  #expect(ids.count == 2)
  #expect(ids[0] != ids[1])
}
#endif
