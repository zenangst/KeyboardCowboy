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
      HStack(spacing: 4) {
        ForEach(hudProvider.state) { keyboardShortcut in
          if let modifiers = keyboardShortcut.modifiers,
             !modifiers.isEmpty {
            ForEach(modifiers) { modifier in
              ModifierKeyIcon(key: modifier)
            }
          } else {
            RegularKeyIcon(letter: "\(keyboardShortcut.key)")
              .aspectRatio(contentMode: .fit)
              .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
          }
        }
      }.frame(height: 32)
    }
    .padding(2)
    .animation(.easeInOut)
    .onReceive(hudProvider.publisher, perform: { _ in
      let screenOffset = NSScreen.main?.visibleFrame.origin.x ?? 0
      let x = 4 + screenOffset
      window?.setFrameOrigin(.init(x: x, y: 0))
    })
  }
}

struct HUDStack_Previews: PreviewProvider {
  static var previews: some View {
    HUDStack(hudProvider: HUDPreviewProvider().erase())
      .frame(width: 600)
  }
}
