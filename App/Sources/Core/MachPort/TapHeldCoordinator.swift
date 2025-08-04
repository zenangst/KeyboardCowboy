import CoreGraphics
import Foundation
import MachPort

@MainActor
protocol TapHeldCoordinatorDelegate: AnyObject {
  func tapHeldChangedState(_ state: TapHeldCoordinator.State?)
  func tapHeldDidResign()
}

@MainActor
final class TapHeldCoordinator: @unchecked Sendable {
  weak var delegate: TapHeldCoordinatorDelegate?
  @MainActor var machPort: MachPortEventController?

  enum State: Equatable {
    case idle
    case event(_ kind: Kind, holdDuration: Double)

    enum Kind: Equatable {
      case tap
      case leader
      case held
    }
  }

  private let defaultPartialMatch: PartialMatch
  private var workItem: DispatchWorkItem?
  private var leaderItem: DispatchWorkItem?
  private(set) var state: State = .idle {
    willSet {
      if case .idle = newValue,
         case .event(let kind, _) = state,
         kind == .held {
        delegate?.tapHeldDidResign()
      }
    }
  }
  private var lastKeyDownTime: Double
  private var lastEventTime: Double
  private var switchedEvents: [Int64: Int64] = [Int64: Int64]()

  private var leaderEvent: MachPortEvent? {
    willSet {
      previousLeader = leaderEvent
    }
  }
  private var previousLeader: MachPortEvent?

  init(defaultPartialMatch: PartialMatch = .default()) {
    self.state = .idle
    self.defaultPartialMatch = defaultPartialMatch
    self.lastKeyDownTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
    self.lastEventTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
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

    if machPortEvent.type == .keyUp {
      lastKeyDownTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
    }

    switch state {
    case .idle:
      return handleIdle(partialMatch, machPortEvent: machPortEvent)
    case .event(let kind, let holdDuration):
      guard let leaderEvent else {
        delegate?.tapHeldChangedState(nil)
        reset()
        return false
      }

      if !isLeader(machPortEvent), let partialMatch, condition(partialMatch) != nil {
        postKeyDownAndUp(leaderEvent)
        self.leaderEvent = machPortEvent
        workItem?.cancel()
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

  func cancelLeaderKey() {
    leaderItem?.cancel()
  }

  // MARK: Private methods

  private func handleIdle(_ partialMatch: PartialMatch?, machPortEvent: MachPortEvent) -> Bool {
    leaderItem?.cancel()
    if machPortEvent.type == .keyDown || machPortEvent.type == .flagsChanged,
       let partialMatch, let workflow = partialMatch.workflow {
      if let (_, holdDuration) = condition(partialMatch) {
        self.leaderEvent = machPortEvent
        state = .event(.tap, holdDuration: holdDuration)
        handleKeyDown(.tap, newEvent: machPortEvent,
                      leaderEvent: machPortEvent,
                      holdDuration: holdDuration)
        machPortEvent.result = nil
        return true
      } else if workflow.machPortConditions.isLeaderKey {
        let currentTimestamp = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
        let elapsedTime = currentTimestamp - lastKeyDownTime
        lastEventTime = currentTimestamp

        // Handle rapid succession.
        if elapsedTime < 120 || machPortEvent.isRepeat {
          leaderItem?.cancel()
          delegate?.tapHeldChangedState(nil)
          delegate?.tapHeldDidResign()
          if let keyCode = switchedEvents[machPortEvent.keyCode] {
            machPortEvent.set(keyCode, type: .keyDown)
            postKeyDownAndUp(machPortEvent)
            switchedEvents[machPortEvent.keyCode] = nil
          } else {
            // Ignore the previous event and set up a new one to maintain consistency.
            machPortEvent.result = nil
            postKeyDownAndUp(machPortEvent)
          }

          leaderItem = startTimer(delay: 10, completion: { [weak self] in
            guard let self else { return }
            delegate?.tapHeldChangedState(nil)
            delegate?.tapHeldDidResign()
          })

          return true
        }

        self.leaderEvent = machPortEvent
        state = .event(.leader, holdDuration: 0)
        machPortEvent.result = nil

        leaderItem = startTimer(delay: 250) { [weak self] in
          guard let self else { return }
          state = .idle
        }

        return true
      } else {
        return false
      }
    } else {
      if !machPortEvent.isRepeat {
        state = .idle
        leaderEvent = nil
      }
      return false
    }
  }

  private func handleKeyDown(_ kind: State.Kind,
                             newEvent: MachPortEvent,
                             leaderEvent: MachPortEvent,
                             holdDuration: Double) {
    guard !newEvent.isRepeat else {
      return
    }

    // Opt-out if the leader key is interrupted by a flags change.
    if leaderEvent.flags.rawValue != newEvent.flags.rawValue,
       case .event(let kind, _) = state,
       kind == .tap {
      self.state = .idle
      newEvent.result = nil
      resetTime()
      return
    }

    guard isLeader(newEvent) else {
      if case .event(let kind, _) = state,
         kind == .tap {
        switchedEvents[leaderEvent.keyCode] = newEvent.keyCode
        newEvent.set(leaderEvent.keyCode, type: .keyUp)
        newEvent.result = nil
        workItem?.cancel()
        delegate?.tapHeldDidResign()
      }
      return
    }

    resetTime()

    let delay = Int((holdDuration * 1.15) * 1_000)
    workItem?.cancel()
    workItem = startTimer(delay: delay) { [weak self] in
      guard let self else { return }
      let newState = State.event(.held, holdDuration: holdDuration)
      state = newState
      delegate?.tapHeldChangedState(newState)
    }

    newEvent.result = nil
  }

  private func handleKeyUp(_ kind: State.Kind,
                           newEvent: MachPortEvent,
                           leaderEvent: MachPortEvent,
                           holdDuration: Double) {
    if isLeader(newEvent) {
      switch kind {
      case .tap:
        if let keyCode = switchedEvents[leaderEvent.keyCode] {
          newEvent.set(keyCode, type: .keyDown)
          postKeyDownAndUp(newEvent)
          switchedEvents[leaderEvent.keyCode] = nil
        } else {
          // Ignore the previous event and set up a new one to maintain consistency.
          newEvent.result = nil
          postKeyDownAndUp(newEvent)
        }
        delegate?.tapHeldChangedState(state)
        self.reset()
      case .leader:
        leaderItem = startTimer(delay: 100, completion: { [weak self] in
          guard let self else { return }
          delegate?.tapHeldChangedState(nil)
          delegate?.tapHeldDidResign()
          if let keyCode = switchedEvents[leaderEvent.keyCode] {
            newEvent.set(keyCode, type: .keyDown)
            postKeyDownAndUp(newEvent)
            switchedEvents[leaderEvent.keyCode] = nil
          } else {
            // Ignore the previous event and set up a new one to maintain consistency.
            newEvent.result = nil
            postKeyDownAndUp(newEvent)
          }
        })
      case .held:
        let currentTimestamp = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
        let elapsedTime = currentTimestamp - lastEventTime
        let threshold = CGFloat(Int(holdDuration * 1 * 1_000))

        if threshold <= elapsedTime { } else  {
          postKeyDownAndUp(newEvent)
        }

        reset()
        delegate?.tapHeldChangedState(nil)
      }
    } else {
      delegate?.tapHeldChangedState(nil)
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
    self.state = .idle
    self.workItem?.cancel()
    self.workItem = nil
    self.leaderEvent = nil
    self.previousLeader = nil
  }

  private func resetTime() {
    lastEventTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
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

extension MachPortEvent {
  func set(_ keyCode: Int64, type: CGEventType) {
    result?.takeUnretainedValue().setIntegerValueField(.keyboardEventKeycode, value: keyCode)
    result?.takeUnretainedValue().type = type
  }
}
