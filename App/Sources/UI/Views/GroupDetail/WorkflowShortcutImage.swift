import Bonzai
import SwiftUI

struct WorkflowShortcutImage: View {
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

#Preview {
  WorkflowShortcutImage(size: 32)
    .frame(minWidth: 200, minHeight: 120)
    .padding()
}
