import Testing
@testable import UserSpace

@Test func missingSelectionUsesClipboardOnlyForEligibleRoles() {
  #expect(UserSpace.textWithoutSelection(role: .webArea) == nil)
  #expect(UserSpace.textWithoutSelection(role: .group) == nil)
  #expect(UserSpace.textWithoutSelection(role: .textField) == "")
  #expect(UserSpace.textWithoutSelection(role: nil) == "")
}
