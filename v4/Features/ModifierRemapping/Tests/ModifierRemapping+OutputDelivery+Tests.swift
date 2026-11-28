import Carbon
import ModifierRemappingFeature
import Testing

private typealias Remap = ModifierRemapping
private let control = UInt16(kVK_Control)
private let escape = UInt16(kVK_Escape)
private let holdDuration = Duration.milliseconds(200)
private enum SinkFailure: Error, Equatable { case notSubmitted }

private func makeSession() throws -> Remap.Session {
  .init(rule: try #require(Remap.Rule(modifier: .leftControl, tapKeyCode: escape, holdDuration: holdDuration)))
}

@Test func failedHoldDownDoesNotSendAnUnmatchedReleaseDuringReset() throws {
  var session = try makeSession()
  var delivery = Remap.OutputDelivery()
  _ = session.receive(.init(keyCode: control, phase: .down), at: .zero)
  let hold = session.advance(to: holdDuration)
  #expect(throws: SinkFailure.notSubmitted) { try delivery.send(hold) { _ in throw SinkFailure.notSubmitted } }
  #expect(delivery.needsRecovery)
  let plannedCleanup = session.reset()
  #expect(plannedCleanup == [.init(keyCode: control, phase: .up)])
  #expect(throws: Remap.OutputDelivery.Failure.recoveryRequired) {
    try delivery.send(plannedCleanup) { _ in Issue.record("Output must wait for recovery") }
  }
  try delivery.recover { _ in Issue.record("No down was submitted, so no release is owed") }
  #expect(!delivery.needsRecovery)
}

@Test func failedTapReleaseIsRetriedWithoutResendingThePress() throws {
  var session = try makeSession()
  var delivery = Remap.OutputDelivery()
  var submitted: [Remap.Event] = []
  _ = session.receive(.init(keyCode: control, phase: .down), at: .zero)
  let tap = session.receive(.init(keyCode: control, phase: .up), at: .milliseconds(50))
  #expect(throws: SinkFailure.notSubmitted) {
    try delivery.send(tap.output) { event in
      if event.phase == .up { throw SinkFailure.notSubmitted }
      submitted.append(event)
    }
  }
  #expect(submitted == [.init(keyCode: escape, phase: .down)])
  #expect(session.reset().isEmpty)
  #expect(throws: SinkFailure.notSubmitted) { try delivery.recover { _ in throw SinkFailure.notSubmitted } }
  #expect(delivery.needsRecovery)
  try delivery.recover { submitted.append($0) }
  try delivery.recover { _ in Issue.record("A recovered press should not be released again") }
  #expect(!delivery.needsRecovery)
  #expect(submitted == [.init(keyCode: escape, phase: .down), .init(keyCode: escape, phase: .up)])
}
