import Carbon
import CoreGraphics
import IOKit.hidsystem
import KeyboardTriggers
import MachPortSystem
import ModifierRemappingFeature
import Testing

private let control = UInt16(kVK_Control)
private let escape = UInt16(kVK_Escape)
private let letter = UInt16(kVK_ANSI_A)
private let leftControl = CGEventFlags(rawValue: UInt64(NX_DEVICELCTLKEYMASK))
private let rightControl = CGEventFlags(rawValue: UInt64(NX_DEVICERCTLKEYMASK))

@Test func remappedTapMatchesOnceAndTaggedCopiesBypassTheRouter() throws {
  let fixture = try KeyboardHandoff()
  try fixture.send(control, .down, flags: [.maskControl, leftControl], at: .zero)
  #expect(fixture.matches.isEmpty && fixture.taggedTypes.isEmpty)
  try fixture.send(control, .up, at: .milliseconds(50))
  #expect(fixture.matches == ["tap"])
  #expect(fixture.taggedTypes == [.keyDown, .keyUp])
}

@Test func earlyChordAppliesLogicalFlagsBeforeMatchingAndClearsThemOnRelease() throws {
  let fixture = try KeyboardHandoff()
  try fixture.send(control, .down, flags: [.maskControl, leftControl], at: .zero)
  try fixture.send(letter, .repeated, flags: [.maskControl, leftControl, .maskShift], at: .milliseconds(10))
  #expect(fixture.matches.isEmpty && fixture.taggedTypes.isEmpty)
  #expect(fixture.matcherFlags == [.maskShift])
  try fixture.send(letter, .down, flags: [.maskControl, leftControl, .maskShift], at: .milliseconds(20))
  #expect(fixture.matches == ["chord"] && fixture.taggedTypes == [.flagsChanged])
  try fixture.send(letter, .up, flags: [.maskControl, leftControl, .maskShift], at: .milliseconds(30))
  try fixture.send(control, .up, at: .milliseconds(40))
  try fixture.send(letter, .down, flags: [.maskShift], at: .milliseconds(50))
  #expect(fixture.matches == ["chord", "shift"])
  #expect(fixture.taggedTypes == [.flagsChanged, .flagsChanged])
  #expect(fixture.taggedFlags == [[.maskControl, leftControl, .maskShift], []])
}

@Test func deferringLeftControlKeepsAnAlreadyHeldRightControl() throws {
  let fixture = try KeyboardHandoff()
  try fixture.send(control, .down, flags: [.maskControl, leftControl, rightControl], at: .zero)
  try fixture.send(letter, .repeated, flags: [.maskControl, leftControl, rightControl], at: .milliseconds(10))
  #expect(fixture.matcherFlags == [[.maskControl, rightControl]])
  #expect(fixture.matches.isEmpty && fixture.taggedTypes.isEmpty)
}

/// An offline caller for the left-Control rule, not a production flags decoder.
/// System delivery and tap installation are deliberately out of scope.
private final class KeyboardHandoff {
  private let router = MachPortSystem.EventRouter(syntheticSignature: 0x4b43)
  private let poster = MachPortSystem.KeyboardEventPoster(eventSource: nil, syntheticSignature: 0x4b43)
  private var remapper: ModifierRemapping.Session
  private var logicalControl = false
  private var matcher = KeyboardTriggers.SequenceSession(matcher: .init(rules: [
    .init(workflowID: "tap", signature: .init(keyCode: escape, flags: 0)),
    .init(workflowID: "chord", signature: .init(
      keyCode: letter, flags: CGEventFlags([.maskControl, leftControl, .maskShift]).rawValue,
    )),
    .init(workflowID: "shift", signature: .init(keyCode: letter, flags: CGEventFlags.maskShift.rawValue)),
  ]), timeout: .seconds(1))
  private(set) var matches: [String] = []
  private(set) var matcherFlags: [CGEventFlags] = []
  private(set) var taggedTypes: [CGEventType] = []
  private(set) var taggedFlags: [CGEventFlags] = []

  init() throws {
    let rule = try #require(ModifierRemapping.Rule(modifier: .leftControl, tapKeyCode: escape, holdDuration: .milliseconds(200)))
    remapper = .init(rule: rule)
  }

  func send(
    _ code: UInt16, _ phase: ModifierRemapping.Event.Phase,
    flags: CGEventFlags = [], at time: Duration,
  ) throws {
    let input = try #require(CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: phase != .up))
    input.flags = flags
    if code == control { input.type = .flagsChanged }
    input.setIntegerValueField(.keyboardEventAutorepeat, value: phase == .repeated ? 1 : 0)
    var decision: ModifierRemapping.Decision?
    let routed = router.route(input, type: input.type) { event in
      // The fixture supplies the physical edge; decoding flagsChanged is separate.
      let physical = ModifierRemapping.Event(
        keyCode: UInt16(event.keyCode), phase: event.isRepeat ? .repeated : phase,
      )
      let step = remapper.receive(physical, at: time)
      decision = step
      return step.forwardsInput ? .passThrough : .suppress
    }
    let step = try #require(decision)
    for output in step.output {
      if output.keyCode == control {
        logicalControl = output.phase == .down
      } else {
        match(output.keyCode, output.phase, flags: logicalFlags(flags), at: time)
      }
      let tagged = try poster.createEvent(
        keyCode: output.keyCode, action: output.phase == .up ? .up : .down, flags: logicalFlags(flags),
      )
      let bypassed = router.route(tagged, type: tagged.type) { _ in
        Issue.record("Tagged output re-entered the remapper and matcher")
        return .suppress
      }
      #expect(bypassed === tagged)
      taggedTypes.append(tagged.type)
      taggedFlags.append(tagged.flags)
    }
    if routed != nil { match(code, phase, flags: logicalFlags(flags), at: time) }
  }

  private func logicalFlags(_ raw: CGEventFlags) -> CGEventFlags {
    var flags = raw.subtracting([.maskControl, leftControl])
    if logicalControl { flags.insert(leftControl) }
    if flags.contains(leftControl) || flags.contains(rightControl) { flags.insert(.maskControl) }
    return flags
  }

  private func match(_ code: UInt16, _ phase: ModifierRemapping.Event.Phase, flags: CGEventFlags, at time: Duration) {
    matcherFlags.append(flags)
    let signature = KeyboardTriggers.Signature(keyCode: code, flags: flags.rawValue)
    let match: KeyboardTriggers.SequenceMatch
    switch phase {
    case .down: match = matcher.receive(signature, at: time, frontmostBundleIdentifier: nil)
    case .up: match = matcher.releaseDecision(keyCode: code, at: time).match
    case .repeated: match = matcher.receiveRepeat(signature, frontmostBundleIdentifier: nil).match
    }
    if case .exact(let id) = match { matches.append(id) }
  }
}
