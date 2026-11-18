import ApplicationSystem
import Foundation
import Testing

@Test func bundleIdentifierRoundTripsAndExposesItsValue() throws {
  let identifier = ApplicationSystem.BundleIdentifier("com.example.editor")
  let encoded = try JSONEncoder().encode(identifier)

  #expect(identifier.id == "com.example.editor")
  #expect(identifier.description == "com.example.editor")
  #expect(try JSONDecoder().decode(ApplicationSystem.BundleIdentifier.self, from: encoded) == identifier)
}

@Test func bundleIdentifierWildcardsCompareInBothDirections() {
  let wildcard = ApplicationSystem.BundleIdentifier.WildCard.previous
  let identifier = ApplicationSystem.BundleIdentifier("*.*.previous")

  #expect(wildcard.bundleIdentifier == identifier)
  #expect(wildcard == identifier)
  #expect(identifier == wildcard)
}
