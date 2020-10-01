import Cocoa
import SwiftUI

public class MainWindow: NSWindow {
  public init(toolbar: Toolbar) {
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
  }

  public override var canBecomeKey: Bool { true }
  public override var canBecomeMain: Bool { true }
}
