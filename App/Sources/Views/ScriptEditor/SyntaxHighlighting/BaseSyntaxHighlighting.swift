import Cocoa

struct BaseSyntaxHighlighting: SyntaxHighlighting {
  let id: String = "BaseSyntaxHighlighting"

  func highlights(_ font: NSFont) -> [Highlight] {
    [
      // Plain text
//      .init(#"\w+"#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.textColor
//            ]),
//
//      /// String
//      .init(#""[^"]+[^\n]"#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.systemOrange,
//              .backgroundColor: NSColor.systemYellow.withAlphaComponent(0.15),
//            ]),
//      .init(#"""#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.systemOrange.withAlphaComponent(0.75),
//              .backgroundColor: NSColor.clear,
//            ]),
//      /// Digits
//      .init(#"(\d+)"#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.systemPink
//                .blended(withFraction: 0.25, of: .white)!
//            ]),
//      /// Arguments
//      .init(#"\s-{1,}\w+"#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.systemTeal
//            ]),
//      // Path
//      .init(#"\n/|\w+/"#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.systemPurple
//                .blended(withFraction: 0.5, of: .white)!
//                .withAlphaComponent(0.75)
//            ]),
//      // Command
//      .init(#"/(\w+)\s|\n(\w+)"#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.systemPurple
//                .blended(withFraction: 0.25, of: .white)!
//            ]),
//      .init(#"/\w+\s(\w+)"#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.systemPink
//                .blended(withFraction: 0.5, of: .white)!
//                .withAlphaComponent(0.75)
//            ]),
//      // Shebang
//      .init(#"#"#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.systemGreen
//            ]),
//      .init(#"#([^\n]+)"#,
//            attributes: [
//              .font: font,
//              .foregroundColor: NSColor.systemGreen
//                .withAlphaComponent(0.75)
//                .blended(withFraction: 0.25, of: .white)!
//            ]),
    ]
  }

  func keywords(_ font: NSFont) -> [String] {
    []
  }
}
