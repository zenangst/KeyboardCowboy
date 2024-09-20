import SwiftUI

struct HideAllIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemGray.blended(withFraction: 0.25, of: .black)!), location: 0.0),
          .init(color: Color(.systemGray.blended(withFraction: 0.5, of: .black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.yellow.blended(withFraction: 0.1, of: .white)!), location: 0.0),
          .init(color: Color(.orange.blended(withFraction: 0.1, of: .black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
        .mask {
          Image(systemName: "app.fill")
            .font(Font.system(size: size * 0.7, weight: .thin, design: .rounded))
        }
        .offset(y: -size * 0.125)
        .opacity(0.25)

        LinearGradient(stops: [
          .init(color: Color(.yellow.blended(withFraction: 0.1, of: .white)!), location: 0.0),
          .init(color: Color(.orange.blended(withFraction: 0.1, of: .black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
        .mask {
          Image(systemName: "app.fill")
            .font(Font.system(size: size * 0.8, weight: .thin, design: .rounded))
        }
        .offset(y: -size * 0.05)
        .opacity(0.5)

        LinearGradient(stops: [
          .init(color: Color(.yellow.blended(withFraction: 0.1, of: .black)!), location: 0.0),
          .init(color: Color(.orange.blended(withFraction: 0.1, of: .black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
        .mask {
          Image(systemName: "app.fill")
            .font(Font.system(size: size * 0.9, weight: .thin, design: .rounded))
        }
        .overlay {
          Image(systemName: "app.dashed")
            .font(Font.system(size: size * 0.8, weight: .thin, design: .rounded))
            .foregroundStyle(
              LinearGradient(stops: [
                .init(color: Color(.yellow.blended(withFraction: 0.8, of: .white)!).opacity(0.8), location: 0.0),
                .init(color: Color(.orange.blended(withFraction: 0.4, of: .white)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
            .opacity(0.8)

          Image(systemName: "eye.slash")
            .font(Font.system(size: size * 0.4, weight: .regular, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(
              .black,
              LinearGradient(stops: [
                .init(color: Color(.yellow.blended(withFraction: 0.4, of: .white)!), location: 0.0),
                .init(color: Color(.orange.blended(withFraction: 0.6, of: .white)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
            .opacity(0.8)
        }
        .offset(y: size * 0.03)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .drawingGroup(opaque: true)
      .iconShape(size)
  }
}

#Preview {
  IconPreview { HideAllIconView(size: $0) }
}
