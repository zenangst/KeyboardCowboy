import Carbon
import CoreGraphics
import IOKit.hidsystem
import KeyCodeSystem
@testable import KeyboardFeature
import MachPortSystem
import Testing

@MainActor
@Test func executesSavedShortcutLabelsAgainstAReusableLayout() throws {
  let french = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.French")
  let us = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  let recorder = Recorder()
  let events = try Keyboard.execute([
    .init(key: "A", modifiers: [.leftShift]), .init(key: "É"), .init(key: "F1"), .init(key: "#1"),
  ], iterations: 1, resolve: { Keyboard.keyCode(for: $0, in: french) }, canPost: { true }, post: recorder.post)

  let codes = [kVK_ANSI_Q, kVK_ANSI_2, kVK_F1, kVK_ANSI_Keypad1].flatMap { [Int64($0), Int64($0)] }
  #expect(events.map { $0.getIntegerValueField(.keyboardEventKeycode) } == codes)
  #expect(events.first?.flags.contains(.maskShift) == true)
  #expect(Keyboard.keyCode(for: "A", in: us) == kVK_ANSI_A)
  #expect(Keyboard.keyCode(for: "not a key", in: french) == nil)
  #expect(throws: Keyboard.ExecutionError.posterUnavailable) {
    try Keyboard.execute([.init(key: "A")], using: nil, layout: french)
  }
}

@MainActor
@Test func postsTaggedDownUpPairsInShortcutAndIterationOrder() throws {
  let recorder = Recorder()
  var lookups: [String] = []
  let events = try Keyboard.execute([
    .init(key: "a", modifiers: [.leftCommand, .rightShift, .rightOption, .leftControl]),
    .init(key: "é", modifiers: [.rightCommand, .leftShift, .leftOption, .rightControl, .capsLock, .function]),
    .init(key: "F1"),
    .init(key: "←"),
  ], iterations: 2, lookup: { key in
    lookups.append(key)
    return ["A": kVK_ANSI_A, "a": kVK_ANSI_B, "é": kVK_ANSI_E, "F1": kVK_F1, "←": kVK_LeftArrow][key]
  }, canPost: { true }, post: recorder.post)

  let flags: [CGEventFlags] = [
    [.maskNonCoalesced, .maskCommand, .maskShift, .maskAlternate, .maskControl,
     .init(rawValue: UInt64(NX_DEVICELCMDKEYMASK | NX_DEVICERSHIFTKEYMASK | NX_DEVICERALTKEYMASK | NX_DEVICELCTLKEYMASK))],
    [.maskNonCoalesced, .maskCommand, .maskShift, .maskAlternate, .maskControl, .maskAlphaShift,
     .maskSecondaryFn,
     .init(rawValue: UInt64(NX_DEVICERCMDKEYMASK | NX_DEVICELSHIFTKEYMASK | NX_DEVICELALTKEYMASK | NX_DEVICERCTLKEYMASK))],
    [.maskNonCoalesced, .maskSecondaryFn, .init(rawValue: 8)],
    [.maskNonCoalesced, .maskNumericPad],
  ]
  let codes = [kVK_ANSI_A, kVK_ANSI_E, kVK_F1, kVK_LeftArrow]
  let pairCodes = codes.flatMap { [Int64($0), Int64($0)] }
  let pairFlags = flags.flatMap { [$0, $0] }
  let types: [CGEventType] = [.keyDown, .keyUp]
  #expect(events.map(\.type) == Array(repeating: types, count: 8).flatMap { $0 })
  #expect(events.map { $0.getIntegerValueField(.keyboardEventKeycode) } == pairCodes + pairCodes)
  #expect(events.map(\.flags) == pairFlags + pairFlags)
  #expect(lookups == ["A", "É", "é", "F1", "←", "A", "É", "é", "F1", "←"])
  #expect(events.count == recorder.events.count)
  #expect(zip(events, recorder.events).allSatisfy { $0 === $1 })
  #expect(events.allSatisfy {
    $0.getIntegerValueField(.keyboardEventAutorepeat) == 0 &&
      $0.getIntegerValueField(.eventSourceUserData) == 42
  })
}

@MainActor
@Test(arguments: [0, -3])
func clampsIterationsToOne(iterations: Int) throws {
  let recorder = Recorder()
  let events = try Keyboard.execute([.init(key: "f")], iterations: iterations, lookup: { _ in kVK_ANSI_F },
                                    canPost: { true }, post: recorder.post)
  #expect(events.map(\.type) == [.keyDown, .keyUp])
  #expect(events.map(\.flags) == [.maskNonCoalesced, .maskNonCoalesced])
}

@MainActor
@Test func emptyExecutionStillRequiresAPosterButDoesNotLookUpOrPost() throws {
  let lookup: Keyboard.KeyLookup = { _ in
    Issue.record("Unexpected lookup")
    return nil
  }
  #expect(throws: Keyboard.ExecutionError.posterUnavailable) {
    try Keyboard.execute([], using: nil, lookup: lookup)
  }
  let poster = MachPortSystem.KeyboardEventPoster(eventSource: nil, syntheticSignature: 42)
  let events = try Keyboard.execute([], iterations: .max, using: poster, lookup: lookup)
  #expect(events.isEmpty)
}

@MainActor
@Test func permissionDenialStopsBeforeLookupAndPosting() {
  let recorder = Recorder()
  #expect(throws: Keyboard.ExecutionError.postingNotPermitted) {
    try Keyboard.execute([.init(key: "a")], iterations: 1, lookup: { _ in
      Issue.record("Unexpected lookup")
      return nil
    }, canPost: { false }, post: recorder.post)
  }
  #expect(recorder.attempts.isEmpty)
}

@MainActor
@Test(arguments: [nil, -1, Int(UInt16.max) + 1] as [Int?])
func reportsResolutionErrorsAndStopsAtTheFailingShortcut(result: Int?) {
  let recorder = Recorder()
  var lookups: [String] = []
  let error = result.map(Keyboard.ExecutionError.invalidKeyCode) ?? .unresolvedKey("Bad")
  #expect(throws: error) {
    try Keyboard.execute([.init(key: "a"), .init(key: "Bad"), .init(key: "z")], iterations: 2, lookup: { key in
      lookups.append(key)
      return key == "A" ? kVK_ANSI_A : result
    }, canPost: { true }, post: recorder.post)
  }
  #expect(recorder.attempts == [.down, .up])
  #expect(lookups == (result == nil ? ["A", "BAD", "Bad"] : ["A", "BAD"]))
}

@MainActor
@Test(arguments: [1, 2])
func propagatesPostingFailureWithoutRetryOrLaterPosts(failureAt: Int) {
  let recorder = Recorder(failureAt: failureAt)
  var lookups: [String] = []
  #expect(throws: MachPortSystem.KeyboardEventPoster.Error.eventCreationFailed) {
    try Keyboard.execute([.init(key: "a"), .init(key: "z")], iterations: 2, lookup: { key in
      lookups.append(key)
      return kVK_ANSI_A
    }, canPost: { true }, post: recorder.post)
  }
  #expect(recorder.attempts == (failureAt == 1 ? [.down] : [.down, .up]))
  #expect(recorder.events.count == failureAt - 1)
  #expect(lookups == ["A"])
}

@MainActor
private final class Recorder {
  private let poster = MachPortSystem.KeyboardEventPoster(eventSource: nil, syntheticSignature: 42)
  private let failureAt: Int?
  private(set) var attempts: [MachPortSystem.KeyboardEventPoster.KeyAction] = []
  private(set) var events: [CGEvent] = []

  init(failureAt: Int? = nil) {
    self.failureAt = failureAt
  }

  func post(
    _ code: CGKeyCode, _ action: MachPortSystem.KeyboardEventPoster.KeyAction, _ flags: CGEventFlags,
  ) throws -> CGEvent {
    attempts.append(action)
    if attempts.count == failureAt { throw MachPortSystem.KeyboardEventPoster.Error.eventCreationFailed }
    let event = try poster.createEvent(keyCode: code, action: action, flags: flags)
    events.append(event)
    return event
  }
}
