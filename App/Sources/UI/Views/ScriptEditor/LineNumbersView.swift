import Cocoa

final class LineNumbersView: NSRulerView {
  var font: NSFont

  init(_ textView: NSTextView, scrollView: NSScrollView) {
    self.font = textView.font ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    super.init(scrollView: scrollView, orientation: .verticalRuler)
    self.clientView = textView
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func drawHashMarksAndLabels(in rect: NSRect) {
    guard let textView = clientView as? NSTextView,
          let textContainer = textView.textContainer,
          let layoutManager = textView.layoutManager,
          let newLineRegex = try? NSRegularExpression(pattern: "\n", options: []) else { return }

    let visibleGlyphRange = layoutManager.glyphRange(
      forBoundingRect: textView.visibleRect,
      in: textContainer)
    let firstVisibleGlyphCharacterIndex = layoutManager.characterIndexForGlyph(
      at: visibleGlyphRange.location)
    var lineNumber = newLineRegex.numberOfMatches(in: textView.string, options: [], range: NSMakeRange(0, firstVisibleGlyphCharacterIndex)) + 1

    let numberOfLines = textView.string.components(separatedBy: "\n").count
    let width = CGFloat(String(numberOfLines).count) * font.pointSize
    ruleThickness = max(width, textView.font!.pointSize * 2)
    var glyphIndexForStringLine = visibleGlyphRange.location

    while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {
      let characterRangeForStringLine = (textView.string as NSString).lineRange(
        for: NSMakeRange(layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0)
      )
      let glyphRangeForStringLine = layoutManager.glyphRange(forCharacterRange: characterRangeForStringLine, actualCharacterRange: nil)

      var glyphIndexForGlyphLine = glyphIndexForStringLine
      var glyphLineCount = 0

      while (glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine)) {
        var effectiveRange = NSMakeRange(0, 0)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForGlyphLine,
                                                      effectiveRange: &effectiveRange,
                                                      withoutAdditionalLayout: true)

        if glyphLineCount > 0 {
          drawLineNumber("-", y: lineRect.minY, in: textView)
        } else {
          drawLineNumber("\(lineNumber)", y: lineRect.minY, in: textView)
        }

        glyphLineCount += 1
        glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
      }

      glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
      lineNumber += 1
    }

    if layoutManager.extraLineFragmentTextContainer != nil {
      drawLineNumber("\(lineNumber)", y: layoutManager.extraLineFragmentRect.minY, in: textView)
    }
  }

  private func drawLineNumber(_ string: String, y: CGFloat, in textView: NSTextView) {
    let relativePoint = self.convert(CGPoint.zero, from: textView)
    let font = textView.font!
    let attributes: [NSAttributedString.Key: Any] = [
      .font : font.withSize(font.pointSize - 3),
      .foregroundColor: NSColor.gray
    ]
    let offset: CGFloat = 5
    let attributedString = NSAttributedString(string: string, attributes: attributes)
    let x = (ruleThickness - offset) - attributedString.size().width
    attributedString.draw(at: NSPoint(x: x, y: relativePoint.y + y + offset / 2))
  }
}
