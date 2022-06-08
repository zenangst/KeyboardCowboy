import Cocoa

final class InsertionPoint: NSView {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    loadView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func loadView() {
    wantsLayer = true

    let animation = CABasicAnimation(keyPath: "opacity")
    animation.duration = 0.25
    animation.fromValue = 0.5
    animation.toValue = 1
    animation.isAdditive = true
    animation.isRemovedOnCompletion = false
    animation.autoreverses = true
    animation.repeatCount = Float.infinity

    layer?.backgroundColor = NSColor.systemRed.cgColor
    layer?.cornerRadius = 2
    layer?.add(animation, forKey: "pulse")
    layer?.opacity = 0
  }
}
