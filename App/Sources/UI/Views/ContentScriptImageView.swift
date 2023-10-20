import Bonzai
import SwiftUI

struct ContentScriptImageView: View {
  let source: ScriptCommand.Source
  let size: CGFloat

  @ViewBuilder
  var body: some View {
    switch source {
    case .inline:
      ZStack {
        Rectangle()
          .fill(LinearGradient(stops: [
            .init(color: Color.accentColor.opacity(0.2), location: 0.0),
            .init(color: .black, location: 0.2),
            .init(color: .black, location: 1.0),
          ], startPoint: .top, endPoint: .bottom))
          .cornerRadius(8)
          .scaleEffect(0.9)
        RoundedRectangle(cornerRadius: 8)
          .stroke(.black)
          .scaleEffect(0.9)

        Text(">_")
          .font(Font.system(.caption, design: .monospaced))
      }
      .frame(width: size, height: size)
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
