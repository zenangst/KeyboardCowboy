import SwiftUI

struct WarningIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemYellow.blended(withFraction: 0.25, of: .white)!), location: 0.0),
          .init(color: Color(.systemOrange.blended(withFraction: 0.25, of: .black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      )
      .grayscale(0.5)
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay {
        Image(systemName: "exclamationmark.triangle.fill")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundStyle(
            .white,
            LinearGradient(stops: [
              .init(color: Color(.systemYellow.blended(withFraction: 0.25, of: .white)!), location: 0.0),
              .init(color: Color(.systemOrange.blended(withFraction: 0.25, of: .black)!), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
          )
          .frame(width: size * 0.65)
          .shadow(radius: 2, y: 2)
          .offset(x: size * 0.0075)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
      .drawingGroup()
  }
}

#Preview {
  IconPreview { WarningIconView(size: $0) }
}
