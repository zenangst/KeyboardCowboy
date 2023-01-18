import Cocoa

protocol SyntaxHighlighting: Identifiable {
  var id: String { get }
  func highlights(_ font: NSFont) -> [Highlight]
  func keywords(_ font: NSFont) -> [String]
}

extension SyntaxHighlighting {
  func highlight(_ string: String, font: NSFont) -> NSAttributedString {
    let all = NSRange(location: 0, length: string.utf16.count)
    let output = NSMutableAttributedString(
      string: string,
      attributes: [
        .font: font,
        .foregroundColor: NSColor.labelColor,
        .ligature: 2,
      ])

    var allHighlights = highlights(font)
    for keyword in keywords(font) {
      allHighlights.append(
        .init("^\(keyword)|\\s\(keyword)\\s|\(keyword)$", attributes: [
          .font: font.bold,
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
