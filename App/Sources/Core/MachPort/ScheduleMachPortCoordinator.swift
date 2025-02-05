import Foundation
import MachPort

final class ScheduleMachPortCoordinator: @unchecked Sendable {
  private var task: Task<Void, Never>?
  @MainActor var machPort: MachPortEventController?
  private var previousEvent: MachPortEvent?

  enum ScheduledAction: Sendable {
    case captureKeyDown(keyCode: Int)
  }

  let defaultPartialMatch: PartialMatch

  init(defaultPartialMatch: PartialMatch) {
    self.defaultPartialMatch = defaultPartialMatch
  }

  @MainActor
  func handlePartialMatchIfApplicable(_ partialMatch: PartialMatch,
                                      machPortEvent: MachPortEvent,
                                      onTask: @escaping @MainActor @Sendable (ScheduledAction?)  -> Void) -> Bool {
    task?.cancel()
    guard let workflow = partialMatch.workflow,
          workflow.machPortConditions.hasHoldForDelay,
          case .keyboardShortcuts(let keyboardShortcut) = workflow.trigger,
          partialMatch.rawValue != defaultPartialMatch.rawValue,
          let holdDuration = keyboardShortcut.holdDuration, holdDuration > 0 else {
      previousEvent = nil
       return false
    }

    guard !machPortEvent.isRepeat, previousEvent == nil else {
      return true
    }

    previousEvent = machPortEvent

    let seconds: Double = max(min(holdDuration, 0.125), 0.125)
    let milliseconds = Duration.milliseconds(Int(seconds * 1000))

    let task = Task.detached {
      do {
        try await Task.sleep(for: milliseconds)
        await onTask(.captureKeyDown(keyCode: Int(machPortEvent.keyCode)))
      } catch {}
    }

    self.task = task

    return true
  }

  @MainActor
  func cancel() {
    task?.cancel()
    task = nil
  }

  @MainActor
  func removeLastEvent() {
    previousEvent = nil
  }

  @MainActor
  func fireLastEvent() {
    guard let machPortEvent = previousEvent else { return }

    _ = try? machPort?.post(Int(machPortEvent.keyCode), type: .keyDown, flags: machPortEvent.event.flags)
    _ = try? machPort?.post(Int(machPortEvent.keyCode), type: .keyUp, flags: machPortEvent.event.flags)

    previousEvent = nil
  }

  @MainActor
  func exchangeWithPreviousEvent(_ machPortEvent: MachPortEvent) {
    guard let previousEvent else { return }

    let newKeyCode = Int64(previousEvent.keyCode)
    let oldKeyCode = Int64(machPortEvent.keyCode)

    machPortEvent.event.setIntegerValueField(.keyboardEventKeycode, value: newKeyCode)
    machPortEvent.result?.takeUnretainedValue().setIntegerValueField(.keyboardEventKeycode, value: newKeyCode)

    _ = try? machPort?.post(Int(oldKeyCode), type: .keyDown, flags: machPortEvent.event.flags)
  }
}
