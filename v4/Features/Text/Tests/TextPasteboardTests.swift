import AppKit
import Testing
import TextFeature

@Test @MainActor func pasteboardAdapterClearsAndWritesString() {
  let pasteboard = NSPasteboard.withUniqueName()
  defer { pasteboard.releaseGlobally() }
  let adapter = TextPasteboard(pasteboard)

  #expect(pasteboard.setString("old", forType: .string))
  adapter.clear()
  #expect(pasteboard.string(forType: .string) == nil)
  adapter.write("new")
  #expect(pasteboard.string(forType: .string) == "new")
}
