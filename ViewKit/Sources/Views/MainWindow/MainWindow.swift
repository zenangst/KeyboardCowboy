import Cocoa
import SwiftUI

public class MainWindow: NSWindow {
  var onClose: () -> Void

  public init(toolbar: Toolbar, onClose: @escaping () -> Void) {
    self.onClose = onClose
    let contentRect: CGRect = .init(origin: .zero, size: .init(width: 960, height: 480))
    let styleMask: NSWindow.StyleMask = [
      .titled, .closable, .miniaturizable,
      .fullSizeContentView, .unifiedTitleAndToolbar, .resizable]
    super.init(contentRect: contentRect,
               styleMask: styleMask,
               backing: .buffered,
               defer: false)
    self.toolbar = toolbar

    if #available(OSX 11.0, *) {
      toolbarStyle = .unified
    }
    titlebarAppearsTransparent = true
    isReleasedWhenClosed = false
  }

  public override var canBecomeKey: Bool { true }
  public override var canBecomeMain: Bool { true }

  public override func close() {
    super.close()
    onClose()
  }
}
