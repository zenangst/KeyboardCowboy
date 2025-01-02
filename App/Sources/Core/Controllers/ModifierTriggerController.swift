import Cocoa
import Combine
import MachPort

final class ModifierTriggerController: @unchecked Sendable {
  enum State: Sendable {
    case idle
    case keyDown(ModifierTrigger.Kind)
  }

  private var workflowGroupsSubscription: AnyCancellable?
  var machPort: MachPortEventController?
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
  func handleIfApplicable(_ machPortEvent: MachPortEvent) {
    guard let machPort, !cache.isEmpty else { return }

    switch state {
    case .idle:
      handleIdle(machPortEvent, machPort: machPort)
    case .keyDown:
      guard let currentTrigger else { return }

      if machPortEvent.event.type == .keyUp {
        handleKeyUp(machPortEvent, machPort: machPort, currentTrigger: currentTrigger)
      } else if machPortEvent.event.type == .keyDown {
        handleKeyDown(machPortEvent, machPort: machPort, currentTrigger: currentTrigger)
      }
    }
  }

  func cache(_ groups: [WorkflowGroup]) {
    do {
      let signature = CGEventSignature(53, .maskNonCoalesced)
      let key = createKey(signature: signature, bundleIdentifier: "*", userModeKey: "")
      cache[key] = ModifierTrigger(
        id: key,
        kind: .key(.escape),
        manipulator: ModifierTrigger.Manipulator(
          alone: .key(.escape),
          heldDown: .modifiers([.leftControl]),
          timeout: 100
        )
      )
    }

    do {
      let signature = CGEventSignature(48, .maskNonCoalesced)
      let key = createKey(signature: signature, bundleIdentifier: "*", userModeKey: "")
      cache[key] = ModifierTrigger(
        id: key,
        kind: .key(.tab),
        manipulator: ModifierTrigger.Manipulator(
          alone: .key(.tab),
          heldDown: .modifiers([.function]),
          timeout: 100
        )
      )
    }

    for group in groups where !group.isDisabled {
      let bundleIdentifiers: [String]
      if let rule = group.rule {
        bundleIdentifiers = rule.bundleIdentifiers
      } else {
        bundleIdentifiers = ["*"]
      }

      bundleIdentifiers.forEach { bundleIdentifier in
        for workflow in group.workflows where workflow.isEnabled {
          guard case .modifier(let trigger) = workflow.trigger else { continue }

          var flags = CGEventFlags.maskNonCoalesced
          let keyCode: Int64
          switch trigger.kind {
          case .modifiers(let array):
            keyCode = 0
            array.forEach { flags.insert($0.cgEventFlags) }
          case .key(let additionalKey):
            keyCode = additionalKey.keyCode
          }

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

  @MainActor
  private func handleIdle(_ machPortEvent: MachPortEvent, machPort: MachPortEventController) {
    let event = machPortEvent.event
    let signature = CGEventSignature(event.getIntegerValueField(.keyboardEventKeycode), event.flags)
    let trigger = lookup(signature)
    guard let trigger, let manipulator = trigger.manipulator else { return }

    let timeout = manipulator.timeout
    if let heldDown = manipulator.heldDown {
      workItem = startTimer(timeout: Int(timeout)) { [weak self] in
        guard let self else { return }
        state = .keyDown(heldDown)
        switch heldDown {
        case .key(let key):
          _ = try? machPort.post(Int(key.keyCode), type: .keyDown, flags: .maskNonCoalesced)
          _ = try? machPort.post(Int(key.keyCode), type: .keyUp, flags: .maskNonCoalesced)
          machPortEvent.event.setIntegerValueField(.keyboardEventKeycode, value: key.keyCode)
        case .modifiers(let modifiers):
          var flags = CGEventFlags.maskNonCoalesced
          modifiers.forEach { modifier in
            flags.insert(modifier.cgEventFlags)
          }
          _ = try? machPort.post(flags)
        }
      }
    }

    let alone = trigger.manipulator?.alone ?? trigger.kind
    state = .keyDown(alone)
    currentTrigger = trigger
    machPortEvent.result = nil
  }

  private func handleKeyDown(_ machPortEvent: MachPortEvent,
                             machPort: MachPortEventController,
                             currentTrigger: ModifierTrigger) {
    guard case .keyDown(let kind) = state else {
      return
    }

    switch kind {
    case .key(let key):
      _ = try? machPort.post(Int(key.keyCode), type: .keyDown, flags: .maskNonCoalesced)
      machPortEvent.event.setIntegerValueField(.keyboardEventKeycode, value: key.keyCode)
      machPortEvent.result = nil
    case .modifiers(let modifiers):
      modifiers.forEach { modifier in
        machPortEvent.event.flags.insert(modifier.cgEventFlags)
        machPortEvent.result?.takeUnretainedValue().flags.insert(modifier.cgEventFlags)
      }
      if case .key(let key) = currentTrigger.kind,
         machPortEvent.event.getIntegerValueField(.keyboardEventKeycode) == key.keyCode {
        machPortEvent.result = nil
        return
      }
    }
  }

  private func handleKeyUp(_ machPortEvent: MachPortEvent,
                           machPort: MachPortEventController,
                           currentTrigger: ModifierTrigger) {
    let event = machPortEvent.event

    if case .keyDown(let kind) = state {
      switch kind {
      case .key(let key):
        _ = try? machPort.post(Int(key.keyCode), type: .keyDown, flags: .maskNonCoalesced)
        _ = try? machPort.post(Int(key.keyCode), type: .keyUp, flags: .maskNonCoalesced)
        machPortEvent.event.setIntegerValueField(.keyboardEventKeycode, value: key.keyCode)
        machPortEvent.result = nil
      case .modifiers(let modifiers):
        var cgEventFlags: CGEventFlags = CGEventFlags()
        modifiers.forEach { modifier in
          machPortEvent.event.flags.insert(modifier.cgEventFlags)
          machPortEvent.result?.takeUnretainedValue().flags.insert(modifier.cgEventFlags)
          cgEventFlags.insert(modifier.cgEventFlags)
        }

        if case .key(let key) = currentTrigger.kind,
           event.getIntegerValueField(.keyboardEventKeycode) != key.keyCode {
          return
        } else {
          _ = try? machPort.post(.maskNonCoalesced)
          print("release")
        }
      }
    }

    self.state = .idle
    self.workItem?.cancel()
    self.workItem = nil
    self.currentTrigger = nil
  }

  private func startTimer(timeout: Int, completion: @Sendable @escaping () -> Void) -> DispatchWorkItem {
    let deadline = DispatchTime.now() + .milliseconds(timeout)
    let item = DispatchWorkItem(block: completion)
    DispatchQueue.main.asyncAfter(deadline: deadline, execute: item)
    return item
  }

  @MainActor
  private func lookup(_ signature: CGEventSignature) -> ModifierTrigger? {
    let bundleIdentifiers: [String]

    if let frontmostApplication = NSWorkspace.shared.frontmostApplication,
       let bundleIdentifier = frontmostApplication.bundleIdentifier {
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

      for userMode in UserSpace.shared.userModes {
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

  private func createKey(signature: CGEventSignature,
                         bundleIdentifier: String,
                         userModeKey: String) -> String {
    let userModeKey = userModeKey.isEmpty ? "" : ".\(userModeKey)"
    return "\(bundleIdentifier).\(userModeKey)\(signature.id)"
  }
}
