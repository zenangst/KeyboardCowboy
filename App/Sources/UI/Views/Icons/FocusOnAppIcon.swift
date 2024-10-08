import SwiftUI

struct FocusOnAppIcon: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.6, of: .black)!), location: 0.0),
          .init(color: Color(.purple), location: 0.6),
          .init(color: Color(.systemPurple.blended(withFraction: 0.6, of: .white)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
      )
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemTeal), location: 0.5),
          .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 1.0),
        ], startPoint: .topTrailing, endPoint: .bottomTrailing)
        .opacity(0.6)
      }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 0.2),
          .init(color: Color.clear, location: 0.8),
        ], startPoint: .topTrailing, endPoint: .bottomLeading)
      }
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay {
        Group {
          ZStack {
            FocusOnAppIconIllustrationApp(size: size * 0.5)
              .mask {
                LinearGradient(stops: [
                  .init(color: .black.opacity(0.6), location: 0),
                  .init(color: .clear, location: 0.5)
                ], startPoint: .top, endPoint: .bottom)
              }
              .offset(y: -size * 0.145)

            FocusOnAppIconIllustrationApp(size: size * 0.6)
              .mask {
                LinearGradient(stops: [
                  .init(color: .black.opacity(0.6), location: 0),
                  .init(color: .clear, location: 0.5)
                ], startPoint: .top, endPoint: .bottom)
              }
              .offset(y: -size * 0.055)
            FocusOnAppIconIllustrationApp(size: size * 0.65)
              .offset(y: size * 0.015)
          }

          Image(systemName: "moon.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size * 0.4)
            .shadow(color: Color(.systemPurple.blended(withFraction: 0.35, of: .black)!).opacity(0.5), radius: 10, y: 6)
        }
        .compositingGroup()
        .shadow(radius: 2, y: 2)
        .frame(width: size / 1.25, height: size / 1.25)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

struct FocusOnAppIconIllustrationApp: View {
  let size: CGFloat

  init(size: CGFloat) {
    self.size = size
  }
  var body: some View {
    Image(systemName: "app.fill")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: size, height: size)
      .fontWeight(.light)
      .mask {
        LinearGradient(
          stops: [.init(color: .black, location: 0.25),
                  .init(color: .black.opacity(0.5), location: 1)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
  }
}

struct FocusOnAppIconIllustration: View {
  let size: CGFloat

  init(size: CGFloat) {
    self.size = size
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color.white.opacity(0.4))
      .clipShape(RoundedRectangle(cornerRadius: size * 0.125))
  }
}

#Preview {
  IconPreview { FocusOnAppIcon(size: $0) }
}
