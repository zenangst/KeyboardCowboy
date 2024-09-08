import SwiftUI

struct RepeatLastWorkflowIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(.textBackgroundColor))
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .systemYellow), location: 0.0),
          .init(color: Color(nsColor: .systemMint), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
        .mask {
          Image(systemName: "repeat.1")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .fontWeight(.bold)
        }
        .frame(width: size * 0.6)
        .offset(x: -size * 0.0125, y: size * 0.0125)
        .shadow(radius: 2)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .drawingGroup(opaque: true)
      .iconShape(size)
  }
}

#Preview {
  IconPreview {
    RepeatLastWorkflowIconView(size: $0)
  }
}
