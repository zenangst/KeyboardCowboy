import Foundation
import MachPort

final class ScheduleMachPortCoordinator: @unchecked Sendable {
  @MainActor var machPort: MachPortEventController?
  private var previousEvent: MachPortEvent?
  private(set) var lastEventTime: Double

  enum ScheduledAction: Sendable {
    case captureKeyDown(event: MachPortEvent, holdDuration: Double)
    case postEvent(event: MachPortEvent)
  }

  let defaultPartialMatch: PartialMatch

  init(defaultPartialMatch: PartialMatch) {
    self.defaultPartialMatch = defaultPartialMatch
    self.lastEventTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
  }

  @MainActor
  func handlePartialMatchIfApplicable(_ partialMatch: PartialMatch,
                                      machPortEvent: MachPortEvent,
                                      onTask: @escaping @MainActor @Sendable (ScheduledAction?)  -> Void) -> Bool {
    guard let workflow = partialMatch.workflow,
          workflow.machPortConditions.hasHoldForDelay,
          case .keyboardShortcuts(let keyboardShortcut) = workflow.trigger,
          partialMatch.rawValue != defaultPartialMatch.rawValue,
          let holdDuration = keyboardShortcut.holdDuration, holdDuration > 0 else {
      lastEventTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
      previousEvent = nil
      return false
    }


    guard !machPortEvent.isRepeat else {
      return true
    }

    let elapsedTime = timeSinceLastEvent()
    let seconds = elapsedTime / 1000
    lastEventTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)

    if seconds < holdDuration {
      onTask(.postEvent(event: machPortEvent))
      fireLastEvent()
      return true
    }

    previousEvent = machPortEvent

    onTask(.captureKeyDown(event: machPortEvent, holdDuration:holdDuration))

    return true
  }

  @MainActor
  func resetLastTime() {
    lastEventTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
  }

  @MainActor
  func timeSinceLastEvent() -> Double {
    let currentTimestamp = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
    let elapsedTime = currentTimestamp - lastEventTime
    return elapsedTime
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

  nonisolated static func convertTimestampToMilliseconds(_ timestamp: UInt64) -> Double {
    return Double(timestamp) / 1_000_000 // Convert nanoseconds to milliseconds
  }
}
