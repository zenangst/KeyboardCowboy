import Cocoa

struct SyntaxHighlighting {
  static let highlights: [Highlight] = [
    // Plain text
    .init(#"\w+"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.textColor
          ]),

    /// String
    .init(#""[^"]+[^\n]"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemOrange,
            .backgroundColor: NSColor.systemYellow.withAlphaComponent(0.15),
          ]),
    .init(#"""#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemOrange.withAlphaComponent(0.75),
            .backgroundColor: NSColor.clear,
          ]),
    /// Digits
    .init(#"(\d+)"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemPink
              .blended(withFraction: 0.25, of: .white)!
          ]),
    /// Arguments
    .init(#"\s-{1,}\w+"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemTeal
          ]),
    // Path
    .init(#"\n/|\w+/"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemPurple
              .blended(withFraction: 0.5, of: .white)!
              .withAlphaComponent(0.75)
          ]),
    // Command
    .init(#"/(\w+)\s|\n(\w+)"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemPurple
              .blended(withFraction: 0.25, of: .white)!
          ]),
    .init(#"/\w+\s(\w+)"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemPink
              .blended(withFraction: 0.5, of: .white)!
              .withAlphaComponent(0.75)
          ]),
    // Shebang
    .init(#"#"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemGreen
          ]),
    .init(#"#([^\n]+)"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemGreen
              .withAlphaComponent(0.75)
              .blended(withFraction: 0.25, of: .white)!
          ]),
  ]

  static let keywords: [String] = [
    "end",
    "else",
    "every",
    "if",
    "is",
    "not",
    "of",
    "repeat",
    "to",
    "set",
    "tell",
    "the",
    "try",
    "whose",
    "return"
  ]

  static func highlight(_ string: String) -> NSAttributedString {
    let all = NSRange(location: 0, length: string.utf16.count)
    let output = NSMutableAttributedString(
      string: string,
      attributes: [
        .font: NSFont(name: "Menlo", size: 12)!,
        .foregroundColor: NSColor.labelColor,
        .ligature: 2,
      ])

    var allHighlights = highlights
    for keyword in keywords {
      allHighlights.append(
        .init("^\(keyword)|\\s\(keyword)\\s|\(keyword)$", attributes: [
          .font: NSFont(name: "Menlo", size: 12)!.with(.bold),
          .foregroundColor: NSColor.systemGreen
            .blended(withFraction: 0.25, of: .white)!
        ])
      )
    }

    for highlight in allHighlights {
      guard let pattern = highlight.pattern else { continue }
      let matches = pattern.matches(in: string, range: all)
      for match in matches {
        let range: NSRange
        if match.numberOfRanges == 2 {
          range = match.range(at: 1)
        } else {
          range = match.range
        }
        output.addAttributes(highlight.attributes, range: range)
      }
    }

    return output
  }
}
