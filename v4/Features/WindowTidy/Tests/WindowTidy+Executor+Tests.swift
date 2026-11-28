import CoreGraphics
import Testing
import WindowTidyFeature

private let display = CGRect(x: -1000, y: 100, width: 1000, height: 800)
private let frame = CGRect(x: -900, y: 225, width: 320, height: 245)
private let anchor = WindowTidy.Window(id: 1, owner: 41, frame: frame, bundleIdentifier: "one")
private let middle = WindowTidy.Window(id: 2, owner: 42, frame: frame, bundleIdentifier: "two")
private let back = WindowTidy.Window(id: 3, owner: 43, frame: frame, bundleIdentifier: "three")

@Test @MainActor func tidyRevalidatesEveryTargetAndRestoresChangedOriginalWindow() async throws {
  var inventory = [anchor, middle, back]
  var calls: [CGWindowID] = []
  let executor = WindowTidy.Executor(
    inventory: { inventory },
    apply: { step in
      calls.append(step.window.id)
      if step.window == back {
        inventory[1] = .init(id: middle.id, owner: 99, frame: middle.frame)
      } else if step.window == anchor {
        inventory[0] = .init(id: anchor.id, owner: anchor.owner, frame: frame.offsetBy(dx: 80, dy: 0),
                             bundleIdentifier: anchor.bundleIdentifier)
      }
      return true
    },
    restore: {
      #expect($0.id == anchor.id && $0.frame != anchor.frame)
      calls.append($0.id)
      return true
    },
  )
  let result = try await executor.run(.init(id: "tidy"), visibleFrame: display)
  #expect(calls == [3, 1, 1])
  #expect(result.applied == [3, 1] && result.skipped == [2] && result.restoredFocus)
}

@Test @MainActor func tidyDoesNotRestoreFocusWhenNothingWasApplied() async throws {
  let executor = WindowTidy.Executor(
    inventory: { [anchor, middle] },
    apply: { _ in false },
    restore: { _ in Issue.record("Unexpected focus"); return true },
  )
  let result = try await executor.run(.init(id: "tidy"), visibleFrame: display)
  #expect(result.applied.isEmpty && result.skipped == [2, 1] && !result.restoredFocus)
}

@Test @MainActor func tidyNeverRestoresAVanishedAnchorOrContinuesAfterCancellation() async throws {
  var inventory = [anchor, middle]
  let vanishing = WindowTidy.Executor(
    inventory: { inventory },
    apply: { _ in inventory.removeAll { $0.id == anchor.id }; return true },
    restore: { _ in Issue.record("Unexpected focus on a stale target"); return true },
  )
  let result = try await vanishing.run(.init(id: "tidy"), visibleFrame: display)
  #expect(result.applied == [2] && result.skipped == [1] && !result.restoredFocus)

  let executor = WindowTidy.Executor(
    inventory: { [anchor, middle] },
    apply: { step in
      #expect(step.window == middle)
      withUnsafeCurrentTask { $0?.cancel() }
      return true
    },
    restore: { _ in Issue.record("Unexpected focus after cancellation"); return true },
  )
  let task = Task { try await executor.run(.init(id: "tidy"), visibleFrame: display) }
  await #expect(throws: CancellationError.self) { try await task.value }
}
