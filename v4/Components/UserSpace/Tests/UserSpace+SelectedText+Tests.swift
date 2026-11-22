import Testing
@testable import UserSpace

@Test func missingSelectionUsesClipboardOnlyForEligibleRoles() {
  #expect(UserSpace.textWithoutSelection(role: "AXWebArea") == nil)
  #expect(UserSpace.textWithoutSelection(role: "AXGroup") == nil)
  #expect(UserSpace.textWithoutSelection(role: "AXTextField") == "")
  #expect(UserSpace.textWithoutSelection(role: nil) == "")
}
