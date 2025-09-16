import Cocoa
import Combine
import MachPort

@MainActor
final class ModifierTriggerController: @unchecked Sendable {
  enum State: Sendable {
    case idle
    case keyDown(ModifierTrigger.Kind, held: Bool)

    fileprivate var debugId: String {
      switch self {
      case .idle: "idle"
      case let .keyDown(_, held): "keyDown(\(held))"
      }
    }
  }

  fileprivate nonisolated(unsafe) static var debug: Bool = false

  var machPort: MachPortEventController? {
    willSet {
      if let newValue {
        coordinator = ModifierTriggerMachPortCoordinator(machPort: newValue)
      }
    }
  }

  var coordinator: ModifierTriggerMachPortCoordinator?

  private var hasDecoratedEvent: Bool = false
  private var lastEventTime: Double = 0
  private var workflowGroupsSubscription: AnyCancellable?
  private var cache: [String: ModifierTrigger] = [:]
  private var state: State = .idle
  private var currentTrigger: ModifierTrigger?
  private var workItem: DispatchWorkItem?

  func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    workflowGroupsSubscription = publisher.sink { [weak self] groups in
      guard let self else { return }

      self.cache(groups)
    }
  }

  @MainActor
  func handleIfApplicable(_ machPortEvent: MachPortEvent) -> Bool {
    guard let coordinator, !cache.isEmpty else { return false }

    // Verify that all modifiers have been released, then to a proper reset.
    if !machPortEvent.isRepeat, machPortEvent.event.type == .keyUp, machPortEvent.flags == .maskNonCoalesced,
       let currentTrigger, Int(machPortEvent.keyCode) == currentTrigger.alone.kind.keyCode
    {
      coordinator
        .discardSystemEvent(on: machPortEvent)
        .postMaskNonCoalesced()
    }

    workItem?.cancel()

    switch state {
    case .idle:
      return handleIdle(machPortEvent, coordinator: coordinator)
    case .keyDown:
      guard let currentTrigger else {
        reset()
        return false
      }

      if machPortEvent.event.type == .keyDown {
        onKeyDown(machPortEvent, coordinator: coordinator, currentTrigger: currentTrigger)
      } else if machPortEvent.event.type == .flagsChanged {
        workItem?.cancel()
        onKeyDown(machPortEvent, coordinator: coordinator, currentTrigger: currentTrigger)
      } else if machPortEvent.event.type == .keyUp {
        workItem?.cancel()
        onKeyUp(machPortEvent, coordinator: coordinator, currentTrigger: currentTrigger)
      }

      return true
    }
  }

  func cache(_ groups: [WorkflowGroup]) {
    guard NSUserName() == "christofferwinterkvist" else {
      return
    }

    // MARK: Demo modifiers

    do {
      let variations: [[CGEventFlags]] = [
        [.maskNonCoalesced],
        [.maskNonCoalesced, .maskAlternate, .maskLeftAlternate],
        [.maskNonCoalesced, .maskAlternate, .maskRightAlternate],
        [.maskNonCoalesced, .maskShift, .maskLeftShift],
        [.maskNonCoalesced, .maskShift, .maskRightShift],
        [.maskNonCoalesced, .maskSecondaryFn],
        [.maskNonCoalesced, .maskCommand, .maskLeftCommand],
        [.maskNonCoalesced, .maskCommand, .maskRightCommand],
      ]
      for variation in variations {
        let flags = variation.reduce(into: CGEventFlags()) { result, flag in
          result.insert(flag)
        }
        let key = KeyShortcut.escape
        let signature = CGEventSignature(Int64(key.keyCode!), flags)
        let keySignature = createKey(signature: signature, bundleIdentifier: "*", userModeKey: "")

        cache[keySignature] = ModifierTrigger(
          id: keySignature,
          alone: .init(kind: .key(key), threshold: 125),
          heldDown: .init(kind: .modifiers([.leftControl]), threshold: 75)
        )
      }
    }

    do {
      let variations: [[CGEventFlags]] = [
        [.maskNonCoalesced],
        [.maskNonCoalesced, .maskAlternate, .maskLeftAlternate],
        [.maskNonCoalesced, .maskAlternate, .maskRightAlternate],
        [.maskNonCoalesced, .maskShift, .maskLeftShift],
        [.maskNonCoalesced, .maskShift, .maskRightShift],
        [.maskNonCoalesced, .maskControl, .maskLeftControl],
        [.maskNonCoalesced, .maskControl, .maskRightControl],
        [.maskNonCoalesced, .maskCommand, .maskLeftCommand],
        [.maskNonCoalesced, .maskCommand, .maskRightCommand],
      ]
      for variation in variations {
        let flags = variation.reduce(into: CGEventFlags()) { result, flag in
          result.insert(flag)
        }

        let key = KeyShortcut.tab
        let signature = CGEventSignature(Int64(key.keyCode!), flags)
        let keySignature = createKey(signature: signature, bundleIdentifier: "*", userModeKey: "")
        cache[keySignature] = ModifierTrigger(
          id: keySignature,
          alone: .init(kind: .key(key), threshold: 125),
          heldDown: .init(kind: .modifiers([.function]), threshold: 75)
        )
      }
    }

    for group in groups where !group.isDisabled {
      let bundleIdentifiers: [String]
      if let rule = group.rule {
        bundleIdentifiers = rule.bundleIdentifiers
      } else {
        bundleIdentifiers = ["*"]
      }

      for bundleIdentifier in bundleIdentifiers {
        for workflow in group.workflows where workflow.isEnabled {
          guard case let .modifier(trigger) = workflow.trigger else { continue }
          guard let resolvedKeyCode = trigger.keyCode else { continue }

          let flags: CGEventFlags

          switch trigger.alone.kind {
          case let .modifiers(modifiers):
            flags = modifiers.cgModifiers
          case .key:
            flags = .maskNonCoalesced
          }

          let keyCode = Int64(resolvedKeyCode)
          let signature = CGEventSignature(keyCode, flags)
          let key = createKey(signature: signature,
                              bundleIdentifier: bundleIdentifier,
                              userModeKey: "")
          cache[key] = trigger

          let userModes = group.userModes
          for userMode in userModes {
            let userModeKey: String = userMode.dictionaryKey(true)
            let key = createKey(signature: signature,
                                bundleIdentifier: bundleIdentifier,
                                userModeKey: userModeKey)
            cache[key] = trigger
          }
        }
      }
    }
  }

  // MARK: Private methods

  private func handleIdle(_ machPortEvent: MachPortEvent, coordinator: ModifierTriggerMachPortCoordinator) -> Bool {
    guard machPortEvent.type == .keyDown || machPortEvent.type == .flagsChanged else { return false }

    let event = machPortEvent.event
    let signature = CGEventSignature(event.getIntegerValueField(.keyboardEventKeycode), event.flags)
    let trigger = lookup(signature)

    guard let trigger else { return false }

    currentTrigger = trigger
    if let heldDown = trigger.heldDown {
      lastEventTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
      state = .keyDown(heldDown.kind, held: true)
      onKeyDown(machPortEvent, coordinator: coordinator, currentTrigger: trigger)
    } else {
      state = .keyDown(trigger.alone.kind, held: false)
      machPortEvent.result = nil
    }

    return true
  }

  private func onKeyDown(_ machPortEvent: MachPortEvent, coordinator: ModifierTriggerMachPortCoordinator, currentTrigger: ModifierTrigger) {
    switch state {
    case let .keyDown(kind, _):
      switch kind {
      case let .key(key):
        coordinator
          .post(key)
          .set(key, on: machPortEvent)
          .discardSystemEvent(on: machPortEvent)
        KeyViewer.instance.handleInput(key)
      case var .modifiers(modifiers):
        if machPortEvent.keyCode == currentTrigger.keyCode! {
          let additionalModifiers = machPortEvent.event.flags.modifierKeys
          for additionalModifiers in additionalModifiers where !modifiers.contains(additionalModifiers) {
            modifiers.append(additionalModifiers)
          }

          coordinator
            .discardSystemEvent(on: machPortEvent)

          machPortEvent.event.type = .flagsChanged
          machPortEvent.event.flags = modifiers.cgModifiers

          guard !machPortEvent.isRepeat else { return }

          lastEventTime = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
          let delay = Int(currentTrigger.alone.threshold - 10)
          workItem = startTimer(delay: delay, currentTrigger: currentTrigger) { [weak self, coordinator] _ in
            guard self != nil else { return }

            coordinator
              .postFlagsChanged(modifiers: modifiers)
          }
        } else {
          coordinator.decorateEvent(machPortEvent, with: modifiers)
        }
      }
    case .idle: break
    }
  }

  private func onKeyUp(_ machPortEvent: MachPortEvent, coordinator: ModifierTriggerMachPortCoordinator, currentTrigger: ModifierTrigger) {
    workItem?.cancel()

    defer { coordinator.setMaskNonCoalesced(on: machPortEvent) }

    switch state {
    case let .keyDown(kind, held):
      switch kind {
      case let .key(key):
        coordinator
          .post(key)
          .set(key, on: machPortEvent)
          .discardSystemEvent(on: machPortEvent)
      case let .modifiers(modifiers):
        let currentTimestamp = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
        let elapsedTime = currentTimestamp - lastEventTime

        if held, currentTrigger.alone.threshold >= elapsedTime {
          switch currentTrigger.alone.kind {
          case let .key(key):
            coordinator
              .post(key)
              .discardSystemEvent(on: machPortEvent)

            KeyViewer.instance.handleInput(key)
          case .modifiers:
            break
          }
          machPortEvent.event.type = .flagsChanged
          machPortEvent.event.flags = .maskNonCoalesced
          reset()
          workItem?.cancel()
          return
        }

        if machPortEvent.keyCode == currentTrigger.keyCode! {
          machPortEvent.event.type = .flagsChanged
          machPortEvent.event.flags = .maskNonCoalesced

          if hasDecoratedEvent {
            coordinator.discardSystemEvent(on: machPortEvent)
          }
        } else {
          coordinator.decorateEvent(machPortEvent, with: modifiers)
          debugModifier("\(machPortEvent.keyCode), \(machPortEvent.event.flags)")
          hasDecoratedEvent = true
          return
        }
      }
    case .idle:
      break
    }

    reset()
  }

  nonisolated static func convertTimestampToMilliseconds(_ timestamp: UInt64) -> Double {
    return Double(timestamp) / 1_000_000 // Convert nanoseconds to milliseconds
  }

  private func reset() {
    state = .idle
    workItem?.cancel()
    workItem = nil
    currentTrigger = nil
    hasDecoratedEvent = false
  }

  private func startTimer(delay: Int, currentTrigger: ModifierTrigger, completion: @MainActor @Sendable @escaping (ModifierTrigger) -> Void) -> DispatchWorkItem {
    let deadline = DispatchTime.now() + .milliseconds(delay)
    let item = DispatchWorkItem(block: { completion(currentTrigger) })
    DispatchQueue.main.asyncAfter(deadline: deadline, execute: item)
    return item
  }

  @MainActor
  private func lookup(_ signature: CGEventSignature) -> ModifierTrigger? {
    let bundleIdentifiers: [String]

    if let frontmostApplication = NSWorkspace.shared.frontmostApplication, let bundleIdentifier = frontmostApplication.bundleIdentifier {
      bundleIdentifiers = [bundleIdentifier, "*"]
    } else {
      bundleIdentifiers = ["*"]
    }

    var trigger: ModifierTrigger?
    outer: for bundleIdentifier in bundleIdentifiers {
      let key = createKey(signature: signature, bundleIdentifier: bundleIdentifier, userModeKey: "")

      if let resolved = cache[key] {
        trigger = resolved
        break outer
      }

      for userMode in UserSpace.shared.currentUserModes {
        let userModeKey = userMode.dictionaryKey(true)
        let key = createKey(signature: signature, bundleIdentifier: bundleIdentifier, userModeKey: userModeKey)
        if let resolved = cache[key] {
          trigger = resolved
          break outer
        }
      }
    }

    return trigger
  }

  private func createKey(signature: CGEventSignature, bundleIdentifier: String, userModeKey: String) -> String {
    let userModeKey = userModeKey.isEmpty ? "" : ".\(userModeKey)"
    return "\(bundleIdentifier).\(userModeKey)\(signature.id)"
  }
}

private func debugModifier(_ handler: @autoclosure @escaping () -> String, function: StaticString = #function, line: UInt = #line) {
  guard ModifierTriggerController.debug else { return }

  let dateFormatter = DateFormatter()
  dateFormatter.dateStyle = .short
  dateFormatter.timeStyle = .short

  let formattedDate = dateFormatter.string(from: Date())

  print(formattedDate, function, line, handler())
}
