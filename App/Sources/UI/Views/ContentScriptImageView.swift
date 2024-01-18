import Bonzai
import SwiftUI

struct ContentScriptImageView: View {
  let source: ScriptCommand.Source
  let size: CGFloat

  @ViewBuilder
  var body: some View {
    switch source {
    case .inline:
      ScriptIconView(size: size - 6)
    case .path:
      IconView(
        icon: .init(
          bundleIdentifier: "/System/Applications/Utilities/Script Editor.app",
          path: "/System/Applications/Utilities/Script Editor.app"
        ),
        size: .init(width: size, height: size)
      )
        .aspectRatio(1, contentMode: .fill)
        .frame(width: 32)
    }
  }
}

struct ContentScriptImageView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ContentScriptImageView(source: .inline("Hello world!"), size: 32)
      ContentScriptImageView(source: .path("~/"), size: 32)
    }
    .frame(minWidth: 200, minHeight: 120)
    .padding()
  }
}
