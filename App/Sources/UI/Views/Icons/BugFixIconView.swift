import SwiftUI

struct BugFixIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(nsColor: .systemGreen), location: 0.25),
          .init(color: Color(nsColor: .systemGreen.blended(withFraction: 0.25, of: NSColor.black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.5) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .systemGreen.blended(withFraction: 0.8, of: .white)!), location: 0.4),
          .init(color: Color(nsColor: .systemGreen), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
        .mask {
          Image(systemName: "ladybug")
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
        .frame(width: size * 0.6)
        .shadow(radius: 2)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .drawingGroup(opaque: true)
      .iconShape(size)
  }
}

#Preview {
  IconPreview(content: { BugFixIconView(size: $0) })
}

