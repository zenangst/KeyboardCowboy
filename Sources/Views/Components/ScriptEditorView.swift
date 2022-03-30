import SwiftUI

struct ScriptEditorView: View {
  @Binding var text: String

  var body: some View {
    ScriptEditorViewable(text: $text)
  }
}

struct ScriptEditorViewable: NSViewRepresentable {
  typealias NSViewType = _ScriptEditorView
  @Binding var text: String

  init(text: Binding<String>) {
    _text = text
  }

  func makeNSView(context: Context) -> _ScriptEditorView {
    let view = _ScriptEditorView(text)
    view.textView.delegate = context.coordinator
    return view
  }

  func updateNSView(_ view: _ScriptEditorView, context: Context) {
    view.updateTextStorage(text)
    view.selectedRanges = context.coordinator.selectedRanges
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  final class Coordinator: NSObject, NSTextViewDelegate {
    var view: ScriptEditorViewable
    var selectedRanges: [NSValue] = []

    init(_ view: ScriptEditorViewable) {
      self.view = view
    }

    public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?
    ) -> Bool {
      return true
    }

    public func textDidBeginEditing(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else {
        return
      }

      view.text = textView.string
    }

    public func textDidChange(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }
      let content = String(textView.textStorage?.string ?? "")

      view.text = content
      selectedRanges = textView.selectedRanges
    }

    public func textDidEndEditing(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else {
        return
      }

      view.text = textView.string
    }
  }
}

final class _ScriptEditorView: NSView {
  private(set) lazy var layoutManager = NSLayoutManager()
  private(set) lazy var scrollView = NSScrollView()
  private(set) lazy var textStorage = NSTextStorage()
  private(set) lazy var textView = NSTextView(frame: .zero, textContainer: textContainer)
  private(set) lazy var textContainer = NSTextContainer(containerSize: scrollView.frame.size)

  var selectedRanges: [NSValue] = [] {
    didSet {
      guard selectedRanges.count > 0 else { return }
      textView.selectedRanges = selectedRanges
    }
  }

  public var text: String {
    didSet { updateTextStorage(text) }
  }

  init(_ text: String) {
    self.text = text
    super.init(frame: .zero)
    updateTextStorage(text)
    loadView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateTextStorage(_ text: String) {
    textStorage.setAttributedString(SyntaxHighlighting.highlight(text))
  }

  private func loadView() {
    scrollView.autoresizingMask = [.width, .height]
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = true
    scrollView.hasHorizontalRuler = false
    scrollView.hasVerticalScroller = true

    textStorage.addLayoutManager(layoutManager)
    textContainer.widthTracksTextView = true
    textContainer.containerSize = NSSize(
      width: scrollView.contentSize.width,
      height: CGFloat.greatestFiniteMagnitude
    )

    layoutManager.addTextContainer(textContainer)

    textView.autoresizingMask = .width
    textView.backgroundColor = NSColor.textBackgroundColor
    textView.drawsBackground = true
    textView.isHorizontallyResizable = false
    textView.isVerticallyResizable = true
    textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)

    addSubview(scrollView)
    scrollView.documentView = textView
  }

  override func viewWillDraw() {
    super.viewWillDraw()
    updateTextStorage(text)
  }
}

struct ScriptEditorView_Previews: PreviewProvider {
  static var previews: some View {
    ScriptEditorView(text: .constant("""
struct ScriptEditorView: View {
  @State var text: String

  var body: some View {
    ScriptEditorViewable(text: $text)
  }
}
"""))
  }
}

fileprivate struct SyntaxHighlighting {
  static let highlights: [Highlight] = [
    .init(#"(struct|var|some)"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!.with(.bold),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.systemPurple
          ]),
    .init(#"(\$\w+|\@\w+)"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!.with(.bold),
            .foregroundColor: NSColor.systemPink
          ]),
    .init(#"(View\s|String\s)"#,
          attributes: [
            .font: NSFont(name: "Menlo", size: 12)!,
            .foregroundColor: NSColor.systemPink
          ])
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

    for highlight in highlights {
      let matches = highlight.pattern.matches(in: string, range: all)
      for match in matches {
        output.addAttributes(highlight.attributes, range: match.range)
      }
    }

    return output
  }
}

struct Highlight {
  let pattern: NSRegularExpression
  let attributes: [NSAttributedString.Key : Any]

  init(_ pattern: String, attributes: [NSAttributedString.Key : Any]) {
    self.pattern = try! NSRegularExpression(pattern: pattern)
    self.attributes = attributes
  }
}

extension NSFont {
    var bold: NSFont {
        return with(.bold)
    }

    var italic: NSFont {
        return with(.italic)
    }

    var boldItalic: NSFont {
        return with([.bold, .italic])
    }

    func with(_ traits: NSFontDescriptor.SymbolicTraits...) -> NSFont {
        let traitSet = NSFontDescriptor.SymbolicTraits(traits).union(fontDescriptor.symbolicTraits)
        let descriptor: NSFontDescriptor = fontDescriptor.withSymbolicTraits(traitSet)
        return NSFont(descriptor: descriptor, size: 0) ?? self
    }

    func without(_ traits: NSFontDescriptor.SymbolicTraits...) -> NSFont {
        let traitSet = fontDescriptor.symbolicTraits.subtracting(NSFontDescriptor.SymbolicTraits(traits))
        let descriptor = fontDescriptor.withSymbolicTraits(traitSet)
        return NSFont(descriptor: descriptor, size: 0) ?? self
    }
}
