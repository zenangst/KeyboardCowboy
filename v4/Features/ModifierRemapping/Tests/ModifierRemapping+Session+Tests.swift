import Carbon
import ModifierRemappingFeature
import Testing

private typealias Remap = ModifierRemapping
private let control = UInt16(kVK_Control)
private let rightControl = UInt16(kVK_RightControl)
private let escape = UInt16(kVK_Escape)
private let letter = UInt16(kVK_ANSI_A)
private let threshold = Duration.milliseconds(200)

private func event(_ code: UInt16, _ phase: Remap.Event.Phase) -> Remap.Event {
  .init(keyCode: code, phase: phase)
}

private func rule() throws -> Remap.Rule {
  try #require(Remap.Rule(modifier: .leftControl, tapKeyCode: escape, holdDuration: threshold))
}

@Test func noRuleLeavesPhysicalEventsUnchanged() {
  var session = Remap.Session()
  for phase in [Remap.Event.Phase.down, .repeated, .up] {
    let result = session.receive(event(control, phase), at: .zero)
    #expect(result.forwardsInput && result.output.isEmpty)
  }
  #expect(session.holdDeadline == nil)
  #expect(Remap.Rule(modifier: .leftControl, tapKeyCode: escape, holdDuration: .zero) == nil)
  #expect(Remap.Rule(modifier: .leftControl, tapKeyCode: rightControl, holdDuration: threshold) == nil)
}

@Test(arguments: [199, 200, 201])
func releaseWithoutTimerUsesExactHoldBoundary(milliseconds: Int) throws {
  var session = Remap.Session(rule: try rule())
  let press = session.receive(event(control, .down), at: .zero)
  #expect(!press.forwardsInput && press.output.isEmpty)
  #expect(session.holdDeadline == threshold)
  let release = session.receive(event(control, .up), at: .milliseconds(milliseconds))
  let expected = milliseconds < 200 ? escape : control
  #expect(!release.forwardsInput && release.output == [event(expected, .down), event(expected, .up)])
  #expect(session.holdDeadline == nil)
  #expect(session.advance(to: .seconds(1)).isEmpty)
}

@Test func earlyChordCommitsHoldBeforeForwardingAndKeepsOtherSideIndependent() throws {
  var session = Remap.Session(rule: try rule())
  _ = session.receive(event(control, .down), at: .zero)
  let repeatEvent = session.receive(event(control, .repeated), at: .milliseconds(10))
  #expect(!repeatEvent.forwardsInput && repeatEvent.output.isEmpty)
  let unrelatedUp = session.receive(event(letter, .up), at: .milliseconds(20))
  #expect(unrelatedUp.forwardsInput && unrelatedUp.output.isEmpty)
  let chord = session.receive(event(rightControl, .down), at: .milliseconds(30))
  #expect(chord.forwardsInput && chord.output == [event(control, .down)])
  let otherRelease = session.receive(event(rightControl, .up), at: .milliseconds(40))
  #expect(otherRelease.forwardsInput && otherRelease.output.isEmpty)
  let release = session.receive(event(control, .up), at: .milliseconds(50))
  #expect(!release.forwardsInput && release.output == [event(control, .up)])
}

@Test(arguments: [false, true])
func disablingMidPressOnlyReleasesAnEmittedHold(held: Bool) throws {
  var session = Remap.Session(rule: try rule())
  _ = session.receive(event(control, .down), at: .zero)
  #expect(session.advance(to: threshold - .milliseconds(1)).isEmpty)
  if held {
    #expect(session.advance(to: threshold) == [event(control, .down)])
    #expect(session.advance(to: threshold).isEmpty)
  }
  #expect(session.updateRule(nil) == (held ? [event(control, .up)] : []))
  #expect(session.reset().isEmpty)
  let staleRelease = session.receive(event(control, .up), at: .seconds(1))
  #expect(!staleRelease.forwardsInput && staleRelease.output.isEmpty)
  #expect(session.receive(event(control, .down), at: .seconds(2)).forwardsInput)
  #expect(session.receive(event(control, .up), at: .seconds(3)).forwardsInput)
}

@Test func resetDoesNotBlockAFreshPressWhenTheOldReleaseWasLost() throws {
  var session = Remap.Session(rule: try rule())
  _ = session.receive(event(control, .down), at: .zero)
  #expect(session.advance(to: threshold) == [event(control, .down)])
  #expect(session.reset() == [event(control, .up)])
  #expect(session.reset().isEmpty)
  #expect(!session.receive(event(control, .repeated), at: .seconds(1)).forwardsInput)
  #expect(!session.receive(event(control, .down), at: .seconds(2)).forwardsInput)
  #expect(session.receive(event(control, .up), at: .seconds(2) + .milliseconds(50)).output
    == [event(escape, .down), event(escape, .up)])
}

@Test(arguments: [false, true])
func enablingWhileTheTapTargetIsHeldDoesNotReleaseIt(releaseBeforeTap: Bool) throws {
  var session = Remap.Session()
  let targetDown = session.receive(event(escape, .down), at: .zero)
  #expect(targetDown.forwardsInput)
  #expect(try session.updateRule(rule()).isEmpty)
  _ = session.receive(event(control, .down), at: .milliseconds(10))
  if releaseBeforeTap {
    #expect(session.receive(event(escape, .up), at: .milliseconds(20)).forwardsInput)
  }

  let tap = session.receive(event(control, .up), at: .milliseconds(30))
  #expect(!tap.forwardsInput)
  #expect(tap.output == (releaseBeforeTap ? [event(escape, .down), event(escape, .up)] : []))
  if !releaseBeforeTap {
    let targetUp = session.receive(event(escape, .up), at: .milliseconds(40))
    #expect(targetUp.forwardsInput && targetUp.output.isEmpty)
  }
}
