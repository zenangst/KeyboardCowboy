import Foundation
import MachPort

final class ScheduleMachPortCoordinator: @unchecked Sendable {
  private var task: Task<Void, Never>?
  @MainActor var machPort: MachPortEventController?

  enum ScheduledAction: Sendable {
    case captureKeyDown(keyCode: Int)
  }

  let defaultPartialMatch: PartialMatch

  init(defaultPartialMatch: PartialMatch) {
    self.defaultPartialMatch = defaultPartialMatch
  }

  func handlePartialMatchIfApplicable(_ partialMatch: PartialMatch,
                                      machPortEvent: MachPortEvent,
                                      onTask: @escaping @Sendable (ScheduledAction?)  -> Void) -> Bool {
    guard let workflow = partialMatch.workflow,
          workflow.machPortConditions.hasHoldForDelay,
          case .keyboardShortcuts(let keyboardShortcut) = workflow.trigger,
          partialMatch.rawValue != defaultPartialMatch.rawValue,
          let holdDuration = keyboardShortcut.holdDuration, holdDuration > 0 else {
       onTask(nil)
       return false
    }

    guard !machPortEvent.isRepeat else {
      return true
    }

    task?.cancel()
    let seconds: Double = max(holdDuration, 0.1)
    let milliseconds = Duration.milliseconds(Int(seconds * 1000))
    let task = Task.detached { [weak self] in
      guard let self else { return }
      try? await Task.sleep(for: milliseconds)
      do {
        try Task.checkCancellation()
        onTask(.captureKeyDown(keyCode: Int(machPortEvent.keyCode)))
      } catch {
        onTask(nil)
        let keyCode = Int(machPortEvent.keyCode)
        _ = try? await machPort?.post(keyCode, type: .keyDown, flags: machPortEvent.event.flags)
        _ = try? await machPort?.post(keyCode, type: .keyUp, flags: machPortEvent.event.flags)
       }
    }

    self.task = task

    return true
  }

  func cancel() {
    task?.cancel()
    task = nil
  }
}
