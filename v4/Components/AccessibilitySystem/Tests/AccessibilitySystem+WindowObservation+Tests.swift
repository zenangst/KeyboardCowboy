@testable import AccessibilitySystem
import Testing

private typealias AX = AccessibilitySystem // swiftlint:disable:this type_name

@MainActor
private final class Registration: AX.WindowRegistration {
  let pid: Int32
  let send: @MainActor (AX.WindowEvent) -> Void
  let failOn: AX.WindowEvent?
  var added: [AX.WindowEvent] = []
  var installs = 0
  var stops = 0

  init(pid: Int32, send: @escaping @MainActor (AX.WindowEvent) -> Void, failOn: AX.WindowEvent? = nil) {
    self.pid = pid
    self.send = send
    self.failOn = failOn
  }

  func add(_ event: AX.WindowEvent) throws {
    if event == failOn { throw AX.Failure(.apiDisabled, operation: "register", rawAXStatus: -25211) }
    added.append(event)
  }

  func install() { installs += 1 }
  func stop() {
    stops += 1
    send(.elementDestroyed) // Simulate an in-flight callback during teardown.
  }
}

@Test @MainActor func windowObservationRollsBackPartialRegistration() throws {
  var registrations: [Registration] = []
  let observation = AX.WindowObservation { pid, send in
    let registration = Registration(pid: pid, send: send, failOn: pid == 2 ? .focusChanged : nil)
    registrations.append(registration)
    return registration
  }
  var events: [AX.WindowEvent] = []
  try observation.start(processIdentifier: 1) { events.append($0) }
  do {
    try observation.start(processIdentifier: 2) { events.append($0) }
    Issue.record("Expected the second registration to fail")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .apiDisabled)
    #expect(failure.rawAXStatus == -25211)
  }

  #expect(registrations.map(\.pid) == [1, 2])
  #expect(registrations.map(\.added) == [AX.WindowEvent.allCases, [.created]])
  #expect(registrations.map(\.installs) == [1, 0])
  observation.stop()
  for registration in registrations { registration.send(.created) }
  #expect(registrations.map(\.stops) == [1, 1])
  #expect(events.isEmpty)
}

@Test @MainActor func windowObservationStopsFromCallbackAndRejectsStaleEventsAfterRestart() throws {
  var registrations: [Registration] = []
  let observation = AX.WindowObservation { pid, send in
    let registration = Registration(pid: pid, send: send)
    registrations.append(registration)
    return registration
  }
  var events: [AX.WindowEvent] = []
  try observation.start(processIdentifier: 1) { [weak observation] event in
    events.append(event)
    observation?.stop()
  }
  registrations[0].send(.created)
  observation.stop()

  // A new application instance can reuse the previous PID.
  try observation.start(processIdentifier: 1) { events.append($0) }
  registrations[0].send(.focusChanged)
  registrations[1].send(.focusChanged)
  observation.stop()
  registrations[1].send(.elementDestroyed)

  #expect(events == [.created, .focusChanged])
  #expect(registrations.map(\.installs) == [1, 1])
  #expect(registrations.map(\.stops) == [1, 1])
}

@Test @MainActor func windowObservationStopsWhenReleased() throws {
  var registration: Registration?
  var observation: AX.WindowObservation? = AX.WindowObservation { pid, send in
    let pending = Registration(pid: pid, send: send)
    registration = pending
    return pending
  }
  try observation?.start(processIdentifier: 1) { _ in
    Issue.record("Teardown must not deliver events")
  }
  observation = nil
  #expect(registration?.stops == 1)
}

@Test @MainActor func windowObservationRejectsInvalidPIDWithoutRequestingTrust() {
  do {
    try AX.WindowObservation().start(processIdentifier: 0) { _ in }
    Issue.record("Expected an invalid PID error")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .invalidConfiguration)
  } catch {
    Issue.record("Unexpected error: \(error)")
  }
}
