import Foundation
import OpenFeature
import Testing

@Test(arguments: [
  "/tmp/a file.txt",
  "relative/path",
  "~/Documents/a file.txt",
  "file:///tmp/a%20file.txt",
  "http://[",
  "",
])
func parsesPathsAsLiteralFileURLs(_ path: String) {
  let parser = OpenURLParser()
  #expect(parser.parse(path) == URL(fileURLWithPath: path))
  #expect(!parser.isBrowserEligible(path))
}

@Test(arguments: [
  ("https://example.com/a%20b", true),
  ("custom://example.com/path", true),
  ("mailto:person@example.com", false),
  ("custom:some-value", false),
])
func preservesSchemesAndSeparatelyChecksBrowserEligibility(_ path: String, eligible: Bool) throws {
  let parser = OpenURLParser()
  #expect(parser.parse(path) == (try #require(URL(string: path))))
  #expect(parser.isBrowserEligible(path) == eligible)
}
