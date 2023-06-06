import Cocoa

struct AppleScriptHighlighting: SyntaxHighlighting {
  let id: String = "AppleScriptHighlighting"

  func highlights(_ font: NSFont) -> [Highlight] {
    [
      .init(#""[^"]+[^\n]"#,
            attributes: [
              .font: font,
              .foregroundColor: NSColor.systemOrange,
              .backgroundColor: NSColor.systemYellow.withAlphaComponent(0.15),
            ]),
    ]
  }

  func keywords(_ font: NSFont) -> [String] {
    [
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
  }
}

