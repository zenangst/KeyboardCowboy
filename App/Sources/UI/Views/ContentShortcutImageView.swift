import Bonzai
import SwiftUI

struct ContentShortcutImageView: View {
  let size: CGFloat

  var body: some View {
    IconView(
      icon: .init(bundleIdentifier: "/System/Applications/Shortcuts.app", 
                  path: "/System/Applications/Shortcuts.app"),
      size: CGSize(width: size, height: size)
    )
      .aspectRatio(1, contentMode: .fill)
      .frame(width: size)
  }
}

struct ContentShortcutImageView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ContentShortcutImageView(size: 32)
    }
    .frame(minWidth: 200, minHeight: 120)
    .padding()
  }
}
