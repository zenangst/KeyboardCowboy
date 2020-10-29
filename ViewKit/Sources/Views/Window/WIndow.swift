import Cocoa
import SwiftUI

public class Window: NSWindow {
  var onClose: () -> Void

  public init(
    autosaveName: String,
    toolbar: Toolbar? = nil,
    onClose: @escaping () -> Void) {
    self.onClose = onClose
    let contentRect: CGRect = .init(origin: .zero, size: .init(width: 960, height: 480))
    let styleMask: NSWindow.StyleMask = [
      .titled, .closable, .miniaturizable,
      .fullSizeContentView, .resizable]
    super.init(contentRect: contentRect,
               styleMask: styleMask,
               backing: .buffered,
               defer: true)
    self.setFrameAutosaveName(frameAutosaveName)
    self.toolbar = toolbar
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .visible
    self.isReleasedWhenClosed = false
  }

  public override var canBecomeKey: Bool { true }
  public override var canBecomeMain: Bool { true }

  public override func close() {
    super.close()
    onClose()
  }
}
