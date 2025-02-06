import Foundation
import MachPort

@MainActor
protocol LeaderKeyCoordinatorDelegate: AnyObject {
  func didResignLeader()
}

@MainActor
final class LeaderKeyCoordinator: @unchecked Sendable {
  weak var delegate: LeaderKeyCoordinatorDelegate?
  @MainActor var machPort: MachPortEventController?

  enum State {
    case idle
    case event(_ kind: Kind, holdDuration: Double)

    enum Kind {
      case fallback
      case leader
    }
  }

  private var workItem: DispatchWorkItem?
  private(set) var state: State = .idle
  private var lastEventTime: Double = 0
  private var shouldPostfallbackEvent: Bool = false

  enum ScheduledAction: Sendable {
    case captureKeyDown(event: MachPortEvent, holdDuration: Double)
    case postEvent(event: MachPortEvent)
    case recoverOnKeyUp(event: MachPortEvent)

    var keyCode: Int {
      switch self {
      case .captureKeyDown(let event, _),
          .recoverOnKeyUp(let event),
          .postEvent(let event):
        Int(event.keyCode)
      }
    }
  }

  let defaultPartialMatch: PartialMatch
  private var leaderEvent: MachPortEvent? {
    willSet {
      previousLeader = leaderEvent
    }
  }
  private var previousLeader: MachPortEvent?

  init(defaultPartialMatch: PartialMatch) {
    self.state = .idle
    self.defaultPartialMatch = defaultPartialMatch
  }

  func isLeader(_ event: MachPortEvent) -> Bool {
    if let leaderEvent {
      return  event.keyCode == leaderEvent.keyCode && event.flags == leaderEvent.flags
    } else if let previousLeader {
      return event.keyCode == previousLeader.keyCode && event.flags == previousLeader.flags
    }

    return false
  }

  @MainActor
  func handlePartialMatchIfApplicable(_ partialMatch: PartialMatch?, machPortEvent: MachPortEvent) -> Bool {
    workItem?.cancel()

    switch state {
    case .idle:
      return handleIdle(partialMatch, machPortEvent: machPortEvent)
    case .event(let kind, let holdDuration):
      guard let leaderEvent else {
        reset()
        return false
      }

      if !isLeader(machPortEvent), let partialMatch, condition(partialMatch) != nil {
        postKeyDownAndUp(leaderEvent)
        self.leaderEvent = machPortEvent
      }

      if machPortEvent.event.type == .keyDown {
        handleKeyDown(kind, newEvent: machPortEvent, leaderEvent: leaderEvent, holdDuration: holdDuration)
      } else if machPortEvent.event.type == .flagsChanged {
        workItem?.cancel()
        handleKeyDown(kind, newEvent: machPortEvent, leaderEvent: leaderEvent, holdDuration: holdDuration)
      } else if machPortEvent.event.type == .keyUp {
        workItem?.cancel()
        handleKeyUp(kind, newEvent: machPortEvent, leaderEvent: leaderEvent, holdDuration: holdDuration)
      }

      return true
    }
  }

  // MARK: Private methods

  private func handleIdle(_ partialMatch: PartialMatch?, machPortEvent: MachPortEvent) -> Bool {
    guard let partialMatch else { return false }
    guard let (_, holdDuration) = condition(partialMatch) else { return false }
    self.leaderEvent = machPortEvent
    state = .event(.fallback, holdDuration: holdDuration)
    handleKeyDown(.fallback, newEvent: machPortEvent,
                  leaderEvent: machPortEvent,
                  holdDuration: holdDuration)
    machPortEvent.result = nil
    return true
  }

  private func handleKeyDown(_ kind: State.Kind,
                             newEvent: MachPortEvent,
                             leaderEvent: MachPortEvent,
                             holdDuration: Double) {
    guard !newEvent.isRepeat, isLeader(newEvent) else {
      return
    }

    lastEventTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
    let delay = Int(holdDuration * 1_000)
    workItem = startTimer(delay: delay) { [weak self] in
      guard self != nil else { return }
      self?.state = .event(.leader, holdDuration: holdDuration)
    }

    newEvent.result = nil
  }

  private func handleKeyUp(_ kind: State.Kind,
                           newEvent: MachPortEvent,
                           leaderEvent: MachPortEvent,
                           holdDuration: Double) {
    if isLeader(newEvent) {
      reset()
      delegate?.didResignLeader()

      switch kind {
      case .fallback:
        postKeyDownAndUp(newEvent)
      case .leader:
        if shouldPostfallbackEvent {
          postKeyDownAndUp(newEvent)
        }
      }
    } else {
      shouldPostfallbackEvent = false
    }
  }

  private func condition(_ partialMatch: PartialMatch) -> (workflow: Workflow, holdDuration: Double)? {
    if let workflow = partialMatch.workflow,
       workflow.machPortConditions.hasHoldForDelay,
       case .keyboardShortcuts(let keyboardShortcut) = workflow.trigger,
       partialMatch.rawValue != defaultPartialMatch.rawValue,
       let holdDuration = keyboardShortcut.holdDuration, holdDuration > 0 {
      return (workflow: workflow, holdDuration: holdDuration)
    }
    return nil
  }

  func reset() {
    self.shouldPostfallbackEvent = true
    self.state = .idle
    self.workItem?.cancel()
    self.workItem = nil
    self.leaderEvent = nil
  }

  private func startTimer(delay: Int, completion: @MainActor @Sendable @escaping () -> Void) -> DispatchWorkItem {
    let deadline = DispatchTime.now() + .milliseconds(delay)
    let item = DispatchWorkItem(block: { completion() })
    DispatchQueue.main.asyncAfter(deadline: deadline, execute: item)
    return item
  }

  nonisolated static func convertTimestampToMilliseconds(_ timestamp: UInt64) -> Double {
    return Double(timestamp) / 1_000_000 // Convert nanoseconds to milliseconds
  }

  private func postKeyDownAndUp(_ event: MachPortEvent) {
    if let result = event.result {
      result.takeUnretainedValue().type = .keyDown
    } else {
      _ = try? machPort?.post(Int(event.keyCode), type: .keyDown, flags: event.flags)
    }
    _ = try? machPort?.post(Int(event.keyCode), type: .keyUp, flags: event.flags)
  }
}
