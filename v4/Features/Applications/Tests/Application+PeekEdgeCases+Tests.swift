@testable import ApplicationsFeature
@testable import CowboyCore
import CoreGraphics
import Foundation
import Testing

private enum PeekEdgeFailure: Error {
  case launch
}

private func peekEdgeCommand(_ name: String, action: String) throws -> Command.Application {
  let fixture = #"{"application":{"bundleIdentifier":"example.\#(name.lowercased())","bundleName":"\#(name)","path":"/Applications/\#(name).app"},"action":"\#(action)","meta":{"id":"\#(name)","name":"\#(name)","enabled":true}}"#
  return try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
}

@Test(arguments: [CGEventType.flagsChanged, .leftMouseDown, .leftMouseUp])
@MainActor func unsupportedPeekEventsRunHookButNoPeekEffects(event: CGEventType) async throws {
  let command = try peekEdgeCommand("Target", action: "peek")
  let snapshot = UserSpace.Snapshot(apps: .init())
  let (events, continuation) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, windowOwnerNames: {
    continuation.yield("owners"); return []
  }, willExecute: { _ in
    continuation.yield("hook")
  }, peekRelease: { _ in
    continuation.yield("release"); return .hide
  }, sleep: { _ in continuation.yield("sleep") })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    continuation.yield("launch"); return .init(.testing(nil))
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { _ in continuation.yield("lookup"); return [] },
      onHide: { _ in continuation.yield("hide"); return true },
      onActivate: { _, _ in continuation.yield("activate"); return true }
    )) {
      let result = try await executor.execute(command, cgEventType: event, snapshot: snapshot)
      #expect(result === snapshot)
    }
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["hook"])
}

@Test @MainActor func peekRoutingIgnoresUnrelatedAndRepeatedEventsWithoutReplacingPress() async throws {
  let command = try peekEdgeCommand("Target", action: "peek")
  let snapshot = UserSpace.Snapshot(apps: .init())
  let session = Application.PeekSession()
  let id = UUID()
  let other = UUID()
  let target = Core.RunningApplication(.testing(.init("example.target")))
  let (events, continuation) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, peekRelease: { _ in
    continuation.yield("release"); return .hide
  })

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { url, _ in
    continuation.yield("launch \(url.lastPathComponent)"); return target
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { identifier in
        #expect(identifier == .init("example.target"))
        continuation.yield("lookup"); return [target]
      }, onHide: { application in
        #expect(application === target)
        continuation.yield("hide"); return true
      }
    )) {
      if await session.begin(id: id, at: .seconds(1)) {
        let result = try await executor.execute(command, cgEventType: .keyDown, snapshot: snapshot)
        #expect(result === snapshot)
      } else {
        Issue.record("Initial press was rejected")
      }
      #expect(await !session.begin(id: id, at: .milliseconds(1400), isRepeat: true))
      #expect(await !session.begin(id: other, at: .milliseconds(1400)))
      #expect(await session.release(id: other, at: .seconds(2)) == .unrelated)
      #expect(await !session.cancel(id: other))
      if await session.release(id: id, at: .milliseconds(1501)) == .hold {
        let result = try await executor.execute(command, cgEventType: .keyUp, snapshot: snapshot)
        #expect(result === snapshot)
      } else {
        Issue.record("Original press was not retained")
      }
      #expect(await session.release(id: id, at: .seconds(3)) == .unrelated)
      #expect(await session.begin(id: other, at: .seconds(3)))
      #expect(await session.cancel(id: other))
    }
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["launch Target.app", "release", "lookup", "hide"])
}

@Test(arguments: [false, true])
@MainActor func failedPeekPressIsCancelledByHostAndSessionCanRestart(cancelled: Bool) async throws {
  let command = try peekEdgeCommand("Target", action: "peek")
  let snapshot = UserSpace.Snapshot(apps: .init())
  let session = Application.PeekSession()
  let id = UUID()
  let nextID = UUID()
  let (events, continuation) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, peekRelease: { _ in
    continuation.yield("release"); return .hide
  })

  let outcome = await withTaskGroup(of: String.self, returning: String.self) { group in
    group.addTask {
      await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { url, _ in
        continuation.yield("launch \(url.lastPathComponent)")
        if cancelled { withUnsafeCurrentTask { $0?.cancel() } }
        throw PeekEdgeFailure.launch
      })) {
        await Core.RunningApplication.Testing.$mock.withValue(.init(
          runningApplicationsLookup: { _ in continuation.yield("lookup"); return [] },
          onHide: { _ in continuation.yield("hide"); return true }
        )) {
          guard await session.begin(id: id, at: .zero) else { return "begin rejected" }
          do {
            _ = try await executor.execute(command, cgEventType: .keyDown, snapshot: snapshot)
            return "unexpected success"
          } catch {
            guard await session.cancel(id: id) else { return "cleanup failed" }
            if error is CancellationError { return "cancelled" }
            if error is PeekEdgeFailure { return "launch error" }
            return "unexpected error"
          }
        }
      }
    }
    return await group.next() ?? "missing outcome"
  }
  #expect(outcome == (cancelled ? "cancelled" : "launch error"))
  #expect(await session.release(id: id, at: .seconds(1)) == .unrelated)
  #expect(await !session.cancel(id: id))
  #expect(await session.begin(id: nextID, at: .seconds(2)))
  #expect(await session.release(id: nextID, at: .milliseconds(2501)) == .hold)
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["launch Target.app"])
}

@Test(arguments: [false, true])
@MainActor func failedPreviousAppRestoreDoesNotLeavePeekSessionActive(cancelled: Bool) async throws {
  let command = try peekEdgeCommand("Target", action: "peek")
  let previous = try peekEdgeCommand("Previous", action: "open")
  let snapshot = UserSpace.Snapshot(apps: .init())
  let session = Application.PeekSession()
  let id = UUID()
  let (events, continuation) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, peekRelease: { _ in
    continuation.yield("release"); return .open(previous)
  })

  let outcome = await withTaskGroup(of: String.self, returning: String.self) { group in
    group.addTask {
      await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { url, _ in
        continuation.yield("launch \(url.lastPathComponent)")
        if url.lastPathComponent == "Previous.app" {
          if cancelled { withUnsafeCurrentTask { $0?.cancel() } }
          throw PeekEdgeFailure.launch
        }
        return .init(.testing(nil))
      })) {
        await Core.RunningApplication.Testing.$mock.withValue(.init(
          runningApplicationsLookup: { _ in continuation.yield("lookup"); return [] },
          onHide: { _ in continuation.yield("hide"); return true }
        )) {
          guard await session.begin(id: id, at: .zero) else { return "begin rejected" }
          do {
            _ = try await executor.execute(command, cgEventType: .keyDown, snapshot: snapshot)
            guard await session.release(id: id, at: .milliseconds(501)) == .hold else { return "not a hold" }
            _ = try await executor.execute(command, cgEventType: .keyUp, snapshot: snapshot)
            return "unexpected success"
          } catch is CancellationError {
            return "cancelled"
          } catch is PeekEdgeFailure {
            return "launch error"
          } catch {
            return "unexpected error"
          }
        }
      }
    }
    return await group.next() ?? "missing outcome"
  }
  #expect(outcome == (cancelled ? "cancelled" : "launch error"))
  #expect(await session.release(id: id, at: .seconds(1)) == .unrelated)
  #expect(await !session.cancel(id: id))
  let nextID = UUID()
  #expect(await session.begin(id: nextID, at: .seconds(2)))
  #expect(await session.release(id: nextID, at: .milliseconds(2500)) == .tap)
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["launch Target.app", "release", "launch Previous.app"])
}
