@testable import RingBuffer
import Foundation
import Testing

@Suite("RingBufferTests")
struct RingBufferTests {
  @Test func rotationTest() {
    let windows = [Window("Ghostty"), Window("Safari"), Window("Reddit")]
    let ring = RingBuffer<Window>(cursor: 0)

    #expect(ring.navigate(.right, entries: windows) == Window("Safari"))
    #expect(ring.cursor == 1)
    #expect(ring.currentEntries == windows)

    #expect(ring.navigate(.right, entries: windows) == Window("Reddit"))
    #expect(ring.cursor == 2)
    #expect(ring.currentEntries == windows)

    #expect(ring.navigate(.right, entries: windows) == Window("Ghostty"))
    #expect(ring.cursor == 0)
    #expect(ring.currentEntries == windows)
  }

  @Test func withTwo() {
    let windows = [Window("Ghostty"), Window("Xcode")]
    let ring = RingBuffer<Window>(cursor: 0)

    #expect(ring.navigate(.right, entries: windows) == Window("Xcode"))
    #expect(ring.cursor == 1)
    #expect(ring.currentEntries == windows)

    #expect(ring.navigate(.right, entries: windows) == Window("Ghostty"))
    #expect(ring.cursor == 0)
    #expect(ring.currentEntries == windows)
  }

  @Test func keepTheCollectionStable() {
    let windows = [Window("Ghostty"), Window("Xcode")]
    let reordered = [Window("Xcode"), Window("Ghostty")]
    let ring = RingBuffer<Window>(cursor: 0)

    #expect(ring.navigate(.right, entries: windows) == Window("Xcode"))
    #expect(ring.currentEntries == windows)
    #expect(ring.cursor == 1)

    #expect(ring.navigate(.right, entries: windows) == Window("Ghostty"))
    #expect(ring.currentEntries == windows)
    #expect(ring.cursor == 0)

    #expect(ring.navigate(.right, entries: reordered) == Window("Xcode"))
    #expect(ring.currentEntries == windows)
    #expect(ring.cursor == 1)
  }

  @Test func randomCollections() {
    let windows = [Window("Ghostty"), Window("Xcode"), Window("Safari"), Window("Reddit")]
    let ring = RingBuffer<Window>(cursor: 1)

    ring.update(windows)
    #expect(ring.currentEntries == windows)

    #expect(ring.navigate(.right, entries: Array(windows.shuffled())) == Window("Safari"))
    #expect(ring.currentEntries == windows)
    #expect(ring.cursor == 2)

    #expect(ring.navigate(.right, entries: Array(windows.shuffled())) == Window("Reddit"))
    #expect(ring.currentEntries == windows)
    #expect(ring.cursor == 3)

    #expect(ring.navigate(.right, entries: Array(windows.shuffled())) == Window("Ghostty"))
    #expect(ring.currentEntries == windows)
    #expect(ring.cursor == 0)
  }

  @Test func growingCollectionWithUpdates() {
    let windows = [Window("Ghostty"), Window("Xcode")]
    let ring = RingBuffer<Window>(cursor: 0)

    ring.update(windows)
    #expect(ring.currentEntries == [Window("Ghostty"), Window("Xcode")])

    ring.update([Window("Xcode"), Window("Ghostty")])
    #expect(ring.currentEntries == [Window("Ghostty"), Window("Xcode")])

    ring.update([Window("Xcode"), Window("Safari"), Window("Ghostty")])
    #expect(ring.currentEntries == [Window("Ghostty"), Window("Safari"), Window("Xcode")])
  }

  @Test func growingCollectionWithNavigation() {
    let windows = [Window("Ghostty"), Window("Xcode")]
    let ring = RingBuffer<Window>(cursor: 0)

    #expect(ring.navigate(.right, entries: windows) == Window("Xcode"))
    #expect(ring.cursor == 1)
    #expect(ring.currentEntries == [Window("Ghostty"), Window("Xcode")])

    let secondBatch = [Window("Ghostty"), Window("Xcode"), Window("Safari")]
    #expect(ring.navigate(.right, entries: secondBatch) == Window("Safari"))
    #expect(ring.currentEntries == secondBatch)
    #expect(ring.currentEntries == [Window("Ghostty"), Window("Xcode"), Window("Safari")])
    #expect(ring.cursor == 2)

    let thirdBatch = [Window("Ghostty"), Window("Xcode"), Window("IMDb"), Window("Safari")]
    #expect(ring.navigate(.left, entries: thirdBatch) == Window("Xcode"))
    #expect(ring.currentEntries == [Window("Ghostty"), Window("Xcode"), Window("Safari"), Window("IMDb")])
    #expect(ring.cursor == 1)

    let fourthBatch = [Window("Ghostty"), Window("IMDb"), Window("Safari")]
    #expect(ring.navigate(.left, entries: fourthBatch) == Window("Ghostty"))
    #expect(ring.currentEntries == [Window("Ghostty"), Window("Safari"), Window("IMDb")])
    #expect(ring.cursor == 0)
  }

  @Test func newRotationEntries() {
    var windows = [Window("Safari"), Window("Ghostty"), Window("Reddit")]
    let ring = RingBuffer<Window>(cursor: 1)

    // Check that the current entries was set
    ring.update(windows)
    #expect(ring.currentEntries == windows)

    ring.update([Window("IMDb"), Window("Safari"), Window("Ghostty"), Window("Reddit")])
    #expect(ring.currentEntries == [Window("Safari"), Window("Ghostty"), Window("IMDb"), Window("Reddit")])

    windows = ring.currentEntries
    #expect(ring.navigate(.right, entries: windows) == Window("IMDb"))
    #expect(ring.cursor == 2)
    #expect(ring.currentEntries == windows)

    #expect(ring.navigate(.left, entries: windows) == Window("Ghostty"))
    #expect(ring.cursor == 1)
    #expect(ring.currentEntries == windows)
  }
}

struct Window: Identifiable, Hashable {
  let id: String

  init(_ id: String) {
    self.id = id
  }
}
