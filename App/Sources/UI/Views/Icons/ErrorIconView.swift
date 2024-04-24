import SwiftUI

struct ErrorIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemGray.blended(withFraction: 0.25, of: .black)!), location: 0.0),
          .init(color: Color(.systemGray.blended(withFraction: 0.5, of: .black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay {
        Image(systemName: "exclamationmark.octagon.fill")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundStyle(
            .white,
            LinearGradient(stops: [
              .init(color: Color(.systemRed.blended(withFraction: 0.25, of: .white)!), location: 0.0),
              .init(color: Color(.systemRed.blended(withFraction: 0.25, of: .black)!), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
            )
          .frame(width: size * 0.65)
          .shadow(radius: 2, y: 2)
          .offset(x: size * 0.0075)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    ErrorIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      ErrorIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        ErrorIconView(size: 64)
        ErrorIconView(size: 32)
        ErrorIconView(size: 16)
      }
    }
  }
  .padding()
}
