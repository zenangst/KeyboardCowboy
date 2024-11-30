import SwiftUI

struct PrivacyIconView: View {
  let size: CGFloat
  var body: some View {
    ZStack {
      InternalPrivayIconView(
        size: size,
        primaryColor: .systemGray,
        secondaryColor: .systemGreen,
        primaryTintColor: .white,
        secondaryTintColor: .yellow
      )

      InternalPrivayIconView(
        size: size,
        primaryColor: .systemGreen,
        secondaryColor: .white,
        primaryTintColor: .systemYellow,
        secondaryTintColor: .white
      )
      .mask(alignment: .trailing) {
        Rectangle()
          .frame(width: size * 0.5)
      }
    }
    .drawingGroup()
  }
}

private struct InternalPrivayIconView: View {
  let size: CGFloat
  let primaryColor: NSColor
  let secondaryColor: NSColor
  let primaryTintColor: NSColor
  let secondaryTintColor: NSColor

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(primaryColor.blended(withFraction: 0.2, of: primaryTintColor)!), location: 0.0),
          .init(color: Color(primaryColor.withSystemEffect(.disabled)), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: secondaryColor.blended(withFraction: 0.5, of: secondaryTintColor)!), location: 0.2),
          .init(color: Color(nsColor: secondaryColor.blended(withFraction: 0.3, of: .black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
        .mask {
          Image(systemName: "shield.lefthalf.filled")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size * 0.5)
        }
        .shadow(radius: 4)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  IconPreview { PrivacyIconView(size: $0) }
}
