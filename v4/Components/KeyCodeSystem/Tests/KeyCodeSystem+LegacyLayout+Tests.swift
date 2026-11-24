import CoreGraphics
import Foundation
import KeyCodeSystem
import Testing

private struct LayoutRow: Decodable {
  let code: Int
  let labels: [String]
}

@MainActor
@Test(arguments: [
  ("ABC", 101), ("US", 101), ("Swedish-Pro", 103), ("Norwegian", 103),
])
func matchesLegacyLayoutLabels(name: String, expectedRows: Int) throws {
  let url = try #require(Bundle.module.url(forResource: "LegacyLayouts", withExtension: "json", subdirectory: "Fixtures"))
  let fixture = try JSONDecoder().decode([String: [LayoutRow]].self, from: Data(contentsOf: url))
  let rows = try #require(fixture[name])
  try #require(rows.count == expectedRows)
  try #require(Set(rows.map(\.code)).count == rows.count)

  let id = "com.apple.keylayout.\(name)"
  let layout = try KeyCodeSystem.Layout(inputSourceID: id)
  let modifiers: [CGEventFlags] = [[], .maskShift, .maskAlternate, [.maskShift, .maskAlternate]]
  for row in rows {
    try #require(row.labels.count == modifiers.count)
    for (flags, label) in zip(modifiers, row.labels) {
      // v4 represents a key with no displayable translation as nil.
      let expected: String? = label.isEmpty ? nil : label
      #expect(layout.displayValue(for: row.code, modifiers: flags) == expected,
              "\(id), key code \(row.code), modifier flags \(flags.rawValue)")
    }
  }
}
