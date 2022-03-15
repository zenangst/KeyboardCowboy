import SwiftUI

struct FeatureIcon<Content: View>: View {
  let content: () -> Content
  let color: Color
  let size: CGSize

  init(color: Color,
       size: CGSize = .init(width: 50, height: 50),
       @ViewBuilder _ content: @escaping () -> Content) {
    self.color = color
    self.content = content
    self.size = size
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(color)
      content()
        .frame(width: size.width / 1.5, height: size.height / 1.5)
    }
    .frame(width: size.width, height: size.width)
  }
}

struct FeatureIcon_Previews: PreviewProvider {
  static let previewSize: CGSize = .init(width: 36, height: 36)

  static var previews: some View {
    HStack {
      FeatureIcon(color: .red, size: previewSize, {
        AppSymbol()
      })
      FeatureIcon(color: .orange, size: previewSize, {
        TypingSymbol(foreground: .orange)
      })
      FeatureIcon(color: .yellow, size: previewSize, {
        ScriptSymbol(cornerRadius: 3,
                     foreground: .yellow,
                     background: .white.opacity(0.7),
                     borderColor: .white)
      })
      FeatureIcon(color: .green, size: previewSize, {
        CommandSymbolIcon(background: .white.opacity(0.85), textColor: Color.green)
      })
      FeatureIcon(color: .blue, size: previewSize, {
        FolderSymbol(cornerRadius: 0.06, textColor: .blue)
      })
      FeatureIcon(color: .purple, size: previewSize, {
        URLSymbol()
      })
      FeatureIcon(color: .gray, size: previewSize, {
        GroupSymbol()
      })
    }
    .redacted(reason: .placeholder)
  }
}
