import Cocoa
import SwiftUI

final class _ScriptEditorView: NSView {
  private lazy var autoCompletionStore: AutoCompletionStore = .init([], selection: nil)
  private lazy var autoCompletionViewController = NSHostingController(rootView: AutoCompletionView(store: autoCompletionStore))
  private(set) lazy var autoComplete = AutoCompletion(autoCompletionStore)

  private(set) lazy var insertionView = InsertionPoint()
  private(set) lazy var layoutManager = NSLayoutManager()
  private(set) lazy var scrollView = NSScrollView()
  private(set) lazy var textStorage = NSTextStorage()
  private(set) lazy var textView = NSTextView(frame: .zero, textContainer: textContainer)
  private(set) lazy var textContainer = NSTextContainer(containerSize: scrollView.frame.size)
  private(set) lazy var lineNumbersView = LineNumbersView(self.textView, scrollView: self.scrollView)

  var selectedRanges: [NSValue] = [] {
    didSet {
      guard selectedRanges.count > 0 else { return }
      textView.selectedRanges = selectedRanges
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
  @Published private(set) public var text: String

  init(_ text: String) {
    self.text = text
    super.init(frame: .zero)
    updateTextStorage(text)
    loadView()
    autoComplete.subscribeToIndex(to: $text)
    autoComplete.textView = textView
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateCursorPosition() {
    guard let window = window else { return }

    let firstRect: NSRect = textView.firstRect(forCharacterRange: textView.selectedRange(), actualRange: nil)

    guard window.firstResponder == textView,
      firstRect.size.height > 0 else {
      insertionView.removeFromSuperview()
      return
    }

    let rect = window.convertFromScreen(firstRect)
    let fromRect = convert(rect, from: nil)
    let toRect = convert(rect, to: scrollView.documentView)

    insertionView.frame.origin.x = fromRect.origin.x - 1 - lineNumbersView.frame.width
    insertionView.frame.origin.y = max(toRect.origin.y + (rect.height * 5), 0) - rect.height / 8 // Why five times?
    insertionView.frame.size = .init(width: 2, height: rect.height + 2)

    scrollView.documentView?.addSubview(insertionView)
  }

  func updateTextStorage(_ text: String) {
    self.text = text
    textStorage.setAttributedString(SyntaxHighlighting.highlight(text))
    lineNumbersView.needsDisplay = true
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
    textView.insertionPointColor = .clear

    addSubview(scrollView)
    scrollView.documentView = textView
    scrollView.verticalRulerView = lineNumbersView
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true
  }

  override func viewWillDraw() {
    super.viewWillDraw()
    updateTextStorage(text)
    lineNumbersView.needsDisplay = true
  }
}
