import Carbon
import Cocoa
import Combine
import SwiftUI

final class _ScriptEditorView: NSView, NSTextStorageDelegate, NSTextViewDelegate {
  private lazy var autoCompletionViewController = NSHostingController(rootView: AutoCompletionView(store: autoCompletionStore))

  let font: NSFont

  private var subscriptions: [AnyCancellable] = []
  private let maxHeight: CGFloat?
  private let autoCompletionStore: AutoCompletionStore
  private let autoComplete: AutoCompletion
  private let textStorage: NSTextStorage

  private(set) lazy var layoutManager = NSLayoutManager()
  private(set) lazy var scrollView = NSScrollView()
  private(set) lazy var textView: NSTextView = ScriptTextView(frame: .zero, textContainer: textContainer)
  private(set) lazy var textContainer = NSTextContainer(containerSize: scrollView.frame.size)
  private(set) lazy var lineNumbersView = LineNumbersView(self.textView, scrollView: self.scrollView)

  var syntax: any SyntaxHighlighting {
    didSet {
      let highlighting = syntax.highlight(textStorage.string, font: font)
      textStorage.setAttributedString(highlighting)
    }
  }

  @Published var currentInput: String = "" {
    didSet {
      autoComplete.currentWord = currentInput
      if currentInput.isEmpty {
        autoCompletionViewController.view.removeFromSuperview()
      }
    }
  }

  override var intrinsicContentSize: NSSize {
    let rect = layoutManager.usedRect(for: textContainer)
    let height: CGFloat
    if let maxHeight {
      height = min(max(rect.height, font.pointSize * 3), maxHeight)
    } else {
      height = max(rect.height, font.pointSize * 3)
    }
    let size = CGSize(width: -1,
                      height: height)
    return size
  }

  @Published private(set) public var text: String

  init(_ text: String, font: NSFont, maxHeight: CGFloat?, syntax: any SyntaxHighlighting) {
    let autoCompletionStore = AutoCompletionStore([], selection: .none)
    self.autoCompletionStore = autoCompletionStore
    self.textStorage = NSTextStorage(attributedString: syntax.highlight(text, font: font))
    self.text = text
    self.syntax = syntax
    self.autoComplete = AutoCompletion(autoCompletionStore, syntax: syntax)
    self.maxHeight = maxHeight
    self.font = font
    super.init(frame: .zero)
    loadView()
    autoComplete.subscribeToIndex(to: $text)
    autoComplete.textView = textView
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func loadView() {
    scrollView.autoresizingMask = [.width, .height]
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = true
    scrollView.hasHorizontalRuler = false
    scrollView.hasVerticalScroller = true
    scrollView.autoresizesSubviews = true

    textStorage.delegate = self
    textStorage.addLayoutManager(layoutManager)

    textContainer.widthTracksTextView = true
    textContainer.containerSize = NSSize(
      width: scrollView.contentSize.width,
      height: CGFloat.greatestFiniteMagnitude
    )

    layoutManager.addTextContainer(textContainer)

    let paragraphStyle = NSMutableParagraphStyle()
    let lineSpacing: CGFloat = 12
    paragraphStyle.lineSpacing = lineSpacing

    textView.autoresizingMask = .width
    textView.backgroundColor = NSColor.textBackgroundColor
    textView.defaultParagraphStyle = paragraphStyle
    textView.delegate = self
    textView.drawsBackground = true
    textView.font = font
    textView.isHorizontallyResizable = false
    textView.isVerticallyResizable = true
    textView.isRichText = false
    textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)

    scrollView.autoresizingMask = [.width, .height]
    scrollView.documentView = textView
    scrollView.verticalRulerView = lineNumbersView
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true

    addSubview(scrollView)

    NotificationCenter.default.publisher(for: NSView.boundsDidChangeNotification)
      .sink { [weak self] notification in
        guard let self else { return }
        guard let clipView = notification.object as? NSClipView,
              clipView == self.scrollView.contentView else { return }
        self.lineNumbersView.needsDisplay = true
      }
      .store(in: &subscriptions)

    NotificationCenter.default.publisher(for: NSScrollView.didLiveScrollNotification)
      .sink { [weak self] notification in
        guard let self else { return }
        guard let clipView = notification.object as? NSClipView,
              clipView == self.scrollView.contentView else { return }
        self.invalidateViews()
      }
      .store(in: &subscriptions)
  }

  @objc func invalidateViews() {
    invalidateIntrinsicContentSize()
    lineNumbersView.needsDisplay = true
  }

  override func viewWillDraw() {
    super.viewWillDraw()
    invalidateViews()
  }

  // MARK: NSTextViewDelegate

  public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?
  ) -> Bool {
    guard let replacementString = replacementString else {
      currentInput = ""
      return true
    }

    let illegalChars = [" ", "\n"]
    if replacementString.count == 1 &&
       !illegalChars.contains(replacementString) {
      currentInput += replacementString
    } else {
      currentInput = ""
    }

    return true
  }

  // MARK: NSTextStorageDelegate

  func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
    let lineRange = textStorage.string.lineRange(atPosition: editedRange.location)
    let line = textStorage.string[lineRange]
    let highlighted = syntax.highlight(String(line), font: font)
    let nsRange = NSRange(lineRange, in: textStorage.string)
    let highlightedRange = NSRange.init(location: 0, length: highlighted.length)

    // TODO: We should find a better way to handle paste commands.
    if delta > 1 {
      let highlighting = syntax.highlight(textStorage.string, font: font)
      textStorage.setAttributedString(highlighting)
    } else {
      highlighted.enumerateAttributes(in: highlightedRange) { value, range, stop in
        let modifiedRange = NSRange.init(location: nsRange.location + range.location,
                                         length: range.length)
        textStorage.addAttributes(value, range: modifiedRange)
      }
    }

    if textStorage.string != text {
      text = textStorage.string
      invalidateIntrinsicContentSize()
      lineNumbersView.animator().needsDisplay = true
    }
  }
}

private extension String {
  func lineRange(atPosition position: Int) -> Range<String.Index> {
    let i = index(startIndex, offsetBy: position)
    return lineRange(for: i ..< i)
  }
}

private final class ScriptTextView: NSTextView {
  override func paste(_ sender: Any?) {
    super.pasteAsPlainText(sender)
  }
}
