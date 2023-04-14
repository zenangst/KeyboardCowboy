import Cocoa

final class SwiftSyntaxHighlighting: SyntaxHighlighting {
  let id: String = "SwiftSyntaxHighlighting"

  func keywords(_ font: NSFont) -> [String] {
    [
      "catch",
      "class",
      "else",
      "enum",
      "if",
      "let",
      "return",
      "some",
      "struct",
      "var",
      "while",
    ]
  }

  func highlights(_ font: NSFont) -> [Highlight] {
    [
      .init(#"\$\w+"#, attributes: [
        .foregroundColor: NSColor.systemMint
      ])
    ]
  }
}
