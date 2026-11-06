import ApplicationsFeature
import Foundation
import Testing

@Test func peekSessionClassifiesTapAndHold() async {
  let session = Application.PeekSession()
  let id = UUID()
  #expect(await session.begin(id: id, at: .seconds(1)))
  #expect(await session.release(id: id, at: .milliseconds(1500)) == .tap)
  #expect(await session.release(id: id, at: .seconds(2)) == .unrelated)
  #expect(await session.begin(id: id, at: .seconds(2)))
  #expect(await session.release(id: id, at: .milliseconds(2501)) == .hold)
  #expect(await session.release(id: id, at: .seconds(3)) == .unrelated)
}

@Test func peekSessionIgnoresUnrelatedAndRepeatedEvents() async {
  let session = Application.PeekSession()
  let id = UUID()
  let other = UUID()
  #expect(await !session.begin(id: id, at: .zero, isRepeat: true))
  #expect(await session.begin(id: id, at: .seconds(1)))
  #expect(await !session.begin(id: id, at: .seconds(2), isRepeat: true))
  #expect(await !session.begin(id: other, at: .seconds(2)))
  #expect(await session.release(id: other, at: .seconds(3)) == .unrelated)
  #expect(await !session.cancel(id: other))
  #expect(await session.release(id: id, at: .milliseconds(1600)) == .hold)
}

@Test func peekSessionCleansUpCancelledAndInvalidEvents() async {
  let session = Application.PeekSession()
  let id = UUID()
  #expect(await session.begin(id: id, at: .seconds(2)))
  #expect(await session.cancel(id: id))
  #expect(await session.release(id: id, at: .seconds(3)) == .unrelated)
  #expect(await session.begin(id: id, at: .seconds(2)))
  #expect(await session.release(id: id, at: .seconds(1)) == .invalidTimestamp)
  #expect(await session.begin(id: UUID(), at: .seconds(3)))
}
