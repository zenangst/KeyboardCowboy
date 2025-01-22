import SwiftUI

struct TriggersIconView: View {
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
        HStack(spacing: size * 0.08) {
          Capsule()
            .fill(
              LinearGradient(stops: [
                .init(color: Color(.systemRed.blended(withFraction: 0.25, of: .systemOrange)!), location: 0.0),
                .init(color: Color(.systemRed.blended(withFraction: 0.5, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
          Capsule()
            .fill(
              LinearGradient(stops: [
                .init(color: Color(.systemYellow.blended(withFraction: 0.25, of: .white)!), location: 0.0),
                .init(color: Color(.systemYellow.blended(withFraction: 0.5, of: .systemOrange)!), location: 0.6),
              ], startPoint: .top, endPoint: .bottom)
            )
          Capsule()
            .fill(
              LinearGradient(stops: [
                .init(color: Color(.systemGreen.blended(withFraction: 0.25, of: .white)!), location: 0.0),
                .init(color: Color(.systemGreen.blended(withFraction: 0.5, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
          Capsule()
            .fill(
              LinearGradient(stops: [
                .init(color: Color(.systemPurple.blended(withFraction: 0.25, of: .white)!), location: 0.0),
                .init(color: Color(.systemPurple.blended(withFraction: 0.5, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
        }
        .mask(
          LinearGradient(stops: [
            .init(color: Color(.black.blended(withFraction: 0.25, of: .white)!), location: 0.0),
            .init(color: Color(.black).opacity(0.5), location: 1.0),
          ], startPoint: .top, endPoint: .bottom)
        )
        .shadow(radius: 8)
        .padding(size * 0.075)
        .background(
          LinearGradient(stops: [
            .init(color: Color(.black.blended(withFraction: 0.25, of: .white)!), location: 0.0),
            .init(color: Color(.black.blended(withFraction: 0.5, of: .black)!), location: 1.0),
          ], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
        .shadow(radius: 4)
        .padding(size * 0.125)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  IconPreview { TriggersIconView(size: $0) }
}
