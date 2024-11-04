import AppKit
import Bonzai

protocol SizeFittingWindow: NSWindow {
  func sizeThatFits(in size: CGSize) -> CGSize
}

extension ZenSwiftUIWindow: SizeFittingWindow {}
