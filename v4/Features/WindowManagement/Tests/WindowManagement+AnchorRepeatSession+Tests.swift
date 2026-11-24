import CoreGraphics
import Foundation
import Testing
@testable import WindowManagementFeature

@Test func anchorRepeatSessionOnlyConsumesAMatchingRepeat() {
  typealias Invocation = WindowManagement.AnchorRepeatSession.Invocation
  let command = UUID()
  let original = Invocation(commandID: command, pid: 42, direction: .top, padding: 0, minimumSize: nil)
  let frame = CGRect(x: 0, y: 0, width: 300, height: 200)
  let point = WindowManagement.AnchorCyclePoint(pid: 42, launchDate: Date(), id: 12, direction: .top,
                                                requested: frame, observed: frame)
  var session = WindowManagement.AnchorRepeatSession()
  for different in [
    Invocation(commandID: UUID(), pid: 42, direction: .top, padding: 0, minimumSize: nil),
    Invocation(commandID: command, pid: 43, direction: .top, padding: 0, minimumSize: nil),
    Invocation(commandID: command, pid: 42, direction: .bottom, padding: 0, minimumSize: nil),
    Invocation(commandID: command, pid: 42, direction: .top, padding: 20, minimumSize: nil),
    Invocation(commandID: command, pid: 42, direction: .top, padding: 0, minimumSize: frame.size),
  ] {
    session.record(point, for: original)
    #expect(session.takePoint(for: different, isRepeat: true) == nil)
    #expect(session.takePoint(for: original, isRepeat: true) == nil)
  }
  session.record(point, for: original)
  #expect(session.takePoint(for: original, isRepeat: false) == nil)
  #expect(session.takePoint(for: original, isRepeat: true) == nil)

  session.record(point, for: original)
  #expect(session.takePoint(for: original, isRepeat: true)?.id == point.id)
  #expect(session.takePoint(for: original, isRepeat: true) == nil)

  session.record(point, for: original)
  session.reset()
  #expect(session.takePoint(for: original, isRepeat: true) == nil)
}

@Test func failedOrUnavailableAnchorDoesNotRetainThePreviousPoint() async throws {
  let command = UUID()
  let invocation = WindowManagement.AnchorRepeatSession.Invocation(commandID: command, pid: -1, direction: .top,
                                                                    padding: -1, minimumSize: nil)
  let frame = CGRect(x: 0, y: 0, width: 300, height: 200)
  let point = WindowManagement.AnchorCyclePoint(pid: -1, launchDate: Date(), id: 12, direction: .top,
                                                requested: frame, observed: frame)
  var session = WindowManagement.AnchorRepeatSession()
  session.record(point, for: invocation)
  await #expect(throws: WindowManagement.AnchorError.invalidPadding) {
    try await session.anchor(commandID: command, isRepeat: true, in: -1, direction: .top, displays: [], padding: -1)
  }
  #expect(session.takePoint(for: invocation, isRepeat: true) == nil)
  let valid = WindowManagement.AnchorRepeatSession.Invocation(commandID: command, pid: -1, direction: .top,
                                                               padding: 0, minimumSize: nil)
  session.record(point, for: valid)
  let unavailable = try await session.anchor(commandID: command, isRepeat: true, in: -1, direction: .top, displays: [])
  #expect(unavailable == nil)
  #expect(session.takePoint(for: valid, isRepeat: true) == nil)
}
