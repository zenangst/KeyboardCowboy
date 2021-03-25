import Cocoa
import SwiftUI

public struct HUDStack: View {
  public weak var window: NSWindow?
  @ObservedObject var hudProvider: HUDProvider

  private let animation = Animation
    .easeOut(duration: 0.33)

  public init(hudProvider: HUDProvider) {
    _hudProvider = ObservedObject(wrappedValue: hudProvider)
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        HStack(spacing: 2) {
          ForEach(hudProvider.state) { keyboardShortcut in
            if hudProvider.state.first != keyboardShortcut,
               hudProvider.state.last != keyboardShortcut {
              Spacer().frame(width: 2)
              Text("+")
                .foregroundColor(Color(.textColor).opacity(0.5))
                .font(Font.system(size: 12, weight: .regular, design: .rounded))
              Spacer().frame(width: 2)
            } else if hudProvider.state.last == keyboardShortcut {
              Spacer().frame(width: 2)
              Text("=")
                .foregroundColor(Color(.textColor).opacity(0.5))
                .font(Font.system(size: 12, weight: .regular, design: .rounded))
              Spacer().frame(width: 2)
            }

            if let modifiers = keyboardShortcut.modifiers,
               !modifiers.isEmpty {
              ForEach(modifiers) { modifier in
                ModifierKeyIcon(key: modifier)
                  .aspectRatio(contentMode: .fit)
              }
            }

            RegularKeyIcon(letter: "\(keyboardShortcut.key)",
                           glow: hudProvider.state.last == keyboardShortcut)
              .aspectRatio(contentMode: .fit)
              .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
              .onAppear(perform: {
                if let lastId = hudProvider.state.last {
                  proxy.scrollTo(lastId)
                }
              })
              .id(keyboardShortcut.id)
          }
        }.frame(height: 32)
      }
      .padding(.vertical, 4)
      .padding(.horizontal, 2)
      .animation(animation)
      .shadow(radius: 1, y: 2)
      .onReceive(hudProvider.publisher, perform: { _ in
        let screenOffset = NSScreen.main?.visibleFrame.origin.x ?? 0
        let x = 4 + screenOffset
        window?.setFrameOrigin(.init(x: x, y: 0))
      })
    }
  }
}

struct HUDStack_Previews: PreviewProvider {
  static var previews: some View {
    HUDStack(hudProvider: HUDPreviewProvider().erase())
      .frame(width: 600)
  }
}
