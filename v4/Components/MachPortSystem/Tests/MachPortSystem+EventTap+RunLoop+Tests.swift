#if DEBUG
import CoreFoundation
import CoreGraphics
import Foundation
@testable import MachPortSystem
import Testing

private final class RunLoopFakeHandle {
  let context: MachPortSystem.EventTap.Context

  init(_ context: MachPortSystem.EventTap.Context) {
    self.context = context
  }
}

@Test func tapLifecycleAndCallbackStopOnBackgroundRunLoop() {
  let finished = DispatchSemaphore(value: 0)
  let thread = Thread {
    defer { finished.signal() }
    #expect(!Thread.isMainThread)
    let owner = CFRunLoopGetCurrent()!
    let mode = CFRunLoopMode.defaultMode!
    var calls: [String] = []
    var currentHandle: RunLoopFakeHandle?
    var tap: MachPortSystem.EventTap?
    var delivered = false

    let operations = MachPortSystem.EventTap.Operations(
      start: { configuration, loop, context in
        #expect(!Thread.isMainThread)
        #expect(CFEqual(CFRunLoopGetCurrent(), owner))
        #expect(CFEqual(loop, owner))
        #expect(configuration.runLoopMode == mode)
        calls.append("start")
        let handle = RunLoopFakeHandle(context)
        currentHandle = handle
        return handle
      },
      stop: { handle, loop, actualMode in
        #expect(!Thread.isMainThread)
        #expect(CFEqual(CFRunLoopGetCurrent(), owner))
        #expect(CFEqual(loop, owner))
        #expect(actualMode == mode)
        #expect(handle === currentHandle)
        calls.append("stop")
        currentHandle = nil
      },
    )
    tap = .init(
      configuration: .init(runLoopMode: mode),
      syntheticSignature: 42,
      handler: { _ in
        #expect(CFEqual(CFRunLoopGetCurrent(), owner))
        calls.append("callback")
        tap?.stop()
        return .suppress
      },
      operations: operations,
    )

    do {
      try tap?.start()
      #expect(tap?.isRunning == true)
      try tap?.reload()
      #expect(tap?.isRunning == true)
      #expect(calls == ["start", "stop", "start"])

      guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 1, keyDown: true),
            let context = currentHandle?.context
      else {
        Issue.record("Could not create event or retrieve fake context")
        tap?.stop()
        return
      }

      CFRunLoopPerformBlock(owner, mode.rawValue) {
        #expect(context.deliver(type: .keyDown, event: event) == nil)
        delivered = true
        CFRunLoopStop(owner)
      }
      CFRunLoopWakeUp(owner)
      // A source keeps the run loop alive while its scheduled block executes.
      var sourceContext = CFRunLoopSourceContext()
      let source = CFRunLoopSourceCreate(nil, 0, &sourceContext)
      guard let source else {
        Issue.record("Could not create run-loop source")
        tap?.stop()
        return
      }

      CFRunLoopAddSource(owner, source, mode)
      CFRunLoopRunInMode(mode, 2, false)
      CFRunLoopRemoveSource(owner, source, mode)
      #expect(delivered)
      #expect(tap?.isRunning == false)
      #expect(calls == ["start", "stop", "start", "callback", "stop"])
      tap?.stop()
      tap = nil
    } catch {
      Issue.record("Unexpected tap lifecycle failure: \(error)")
      tap?.stop()
      tap = nil
    }
  }
  thread.start()
  #expect(finished.wait(timeout: .now() + 5) == .success)
}
#endif
