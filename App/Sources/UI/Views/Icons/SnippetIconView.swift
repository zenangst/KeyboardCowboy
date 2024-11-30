import SwiftUI

struct SnippetIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(.textBackgroundColor))
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay { SnippetIconIllustrationView(size) }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
      .drawingGroup()
  }
}

private struct SnippetIconIllustrationView: View {
  let size: CGFloat

  init(_ size: CGFloat) {
    self.size = size
  }

  var body: some View {
    LinearGradient(stops: [
      .init(color: Color(nsColor: .white), location: 0.2),
      .init(color: Color(nsColor: .systemPink.blended(withFraction: 0.2, of: .white)!), location: 1.0),
    ], startPoint: .topLeading, endPoint: .bottom)
    .mask {
      Image(systemName: "ellipsis.curlybraces")
        .font(Font.system(size: size * 0.6, weight: .bold, design: .monospaced))
    }
    .shadow(color: Color(nsColor: .systemPink.blended(withFraction: 0.4, of: .black)!), radius: 2, y: 1)
  }
}

#Preview {
  IconPreview { SnippetIconView(size: $0) }
}
