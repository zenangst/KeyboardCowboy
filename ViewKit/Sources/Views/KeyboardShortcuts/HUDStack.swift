import Cocoa
import SwiftUI

public struct HUDStack: View {
  public weak var window: NSWindow?
  @ObservedObject var hudProvider: HUDProvider

  public init(hudProvider: HUDProvider) {
    _hudProvider = ObservedObject(wrappedValue: hudProvider)
  }

  public var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 2) {
        ForEach(hudProvider.state) { keyboardShortcut in
          KeyboardSequenceItem(title: keyboardShortcut.modifersDisplayValue, subtitle: keyboardShortcut.key)
            .padding(2)
            .foregroundColor(Color(NSColor.textColor))
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(4)
            .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
        }
      }.frame(minWidth: 32, minHeight: 32)
    }
    .padding(2)
    .animation(.easeInOut)
    .onReceive(hudProvider.publisher, perform: { _ in
      let screenOffset = NSScreen.main?.visibleFrame.origin.x ?? 0
      let x = 4 + screenOffset
      window?.setFrameOrigin(.init(x: x, y: 0))
    })
    .frame(width: 300)
  }
}

struct HUDStack_Previews: PreviewProvider {
  static var previews: some View {
    HUDStack(hudProvider: HUDPreviewProvider().erase())
  }
}
