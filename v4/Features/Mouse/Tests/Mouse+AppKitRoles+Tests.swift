import AppKit
import Testing

@MainActor
@Test func appKitControlRoleMappings() {
  _ = NSApplication.shared
  // Use stock controls without assigning roles or depending on localized descriptions.
  let outline = NSOutlineView()
  let textView = NSTextView()
  let collection = NSCollectionView()
  #expect(outline.accessibilityRole()?.rawValue == "AXOutline")
  #expect(outline.accessibilitySubrole() == nil)
  #expect(textView.accessibilityRole()?.rawValue == "AXTextArea")
  #expect(textView.accessibilitySubrole() == nil)
  #expect(collection.accessibilityRole()?.rawValue == "AXGrid")
  #expect(collection.accessibilitySubrole() == nil)
}
