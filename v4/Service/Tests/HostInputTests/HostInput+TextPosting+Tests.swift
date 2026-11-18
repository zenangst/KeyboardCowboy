import CoreGraphics
@testable import HostInput
import Testing

@MainActor
@Test func textPostingMapsEventsAndModifiers() throws {
  var trace: [(CGKeyCode, Bool, CGEventFlags)] = []
  let post = HostInput.textPosting { code, action, flags in
    trace.append((code, action == .down, flags))
  }
  try post(9, .down, [.command, .option, .shift])
  try post(9, .up, [])
  #expect(trace.map { $0.0 } == [9, 9])
  #expect(trace.map { $0.1 } == [true, false])
  #expect(trace.map { $0.2 } == [[.maskCommand, .maskAlternate, .maskShift], []])
}

@MainActor
@Test func textPostingPreservesMissingPosterNoOpAndRejectsInvalidCodes() throws {
  try HostInput.textPosting(using: nil)(-1, .down, .command)
  let post = HostInput.textPosting { _, _, _ in Issue.record("Unexpected post") }
  #expect(throws: HostInput.PostingError.invalidKeyCode(-1)) { try post(-1, .down, []) }
}
