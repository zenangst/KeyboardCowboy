import Foundation
@testable import OpenFeature
import Testing

private enum WindowFailure: Error {
  case enumeration, lookup, raise
}

@Test func browserWindowMatchingRaisesFirstMatchInAXOrder() throws {
  let match = try #require(URL(string: "https://example.com/match"))
  let other = try #require(URL(string: "https://example.com/other"))
  let urls = [2: other, 1: match, 0: match]
  var searched: [Int] = []
  var raised: [Int] = []

  let matched = try Operation.Browser.raiseMatchingWindow(path: "/match", windows: { [3, 2, 1, 0] }, firstWebAreaURL: {
    searched.append($0)
    return urls[$0]
  }, raise: { raised.append($0) })

  #expect(matched)
  #expect(searched == [3, 2, 1])
  #expect(raised == [1])
}

@Test func browserWindowMatchingReturnsFalseIfNoFirstURLMatches() throws {
  let first = try #require(URL(string: "https://example.com/other"))
  let later = try #require(URL(string: "https://example.com/match"))
  let windows = [[first, later], []]
  let matched = try Operation.Browser.raiseMatchingWindow(
    path: "/match",
    windows: { windows },
    firstWebAreaURL: { $0.first },
    raise: { _ in Issue.record("Unexpected window raise") },
  )
  #expect(!matched)
}

@Test(arguments: [WindowFailure.enumeration, .lookup, .raise])
private func browserWindowMatchingPropagatesFailures(_ failure: WindowFailure) throws {
  let url = try #require(URL(string: "https://example.com/match"))
  #expect(throws: failure) {
    try Operation.Browser.raiseMatchingWindow(
      path: "/match",
      windows: {
        if failure == .enumeration { throw failure }
        return [0]
      },
      firstWebAreaURL: { _ in
        if failure == .lookup { throw failure }
        return url
      },
      raise: { _ in throw WindowFailure.raise },
    )
  }
}
