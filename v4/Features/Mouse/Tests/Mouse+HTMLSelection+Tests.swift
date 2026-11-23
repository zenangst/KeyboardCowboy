@testable import MouseFeature
import Testing

@Test func htmlSelectionMatchesAcrossLeavesCaseInsensitively() {
  var selection = Mouse.HTMLSelection("hello WORLD")
  let focus: () -> Bool = {
    Issue.record("Nonempty selection must not inspect focus")
    return true
  }
  let first = selection.matchesLeaf(text: { "Prefix HELLO " }, isFocusedOrSelected: focus)
  let missing = selection.matchesLeaf(text: { nil }, isFocusedOrSelected: focus)
  let last = selection.matchesLeaf(text: { "world suffix" }, isFocusedOrSelected: focus)
  #expect(!first)
  #expect(!missing)
  #expect(last)
}

@Test func emptyHTMLSelectionUsesFocusOrSelectionWithoutReadingText() {
  var selection = Mouse.HTMLSelection("")
  let text: () -> String? = {
    Issue.record("Empty selection must not read text")
    return nil
  }
  let inactive = selection.matchesLeaf(text: text, isFocusedOrSelected: { false })
  let active = selection.matchesLeaf(text: text, isFocusedOrSelected: { true })
  #expect(!inactive)
  #expect(active)
}
