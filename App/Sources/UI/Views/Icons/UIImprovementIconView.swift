import SwiftUI

struct UIImprovementIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(nsColor: .systemPurple), location: 0.25),
          .init(color: Color(nsColor: .systemIndigo.blended(withFraction: 0.1, of: .black)!), location: 1),
        ], startPoint: .top, endPoint: .bottom),
      )
      .overlay { iconOverlay() }
      .overlay { iconBorder(size) }
      .overlay {
        Text("💅🏻")
          .font(.system(size: size))
          .rotationEffect(.degrees(19))
          .offset(y: size * 0.1)
      }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .white), location: 0),
          .init(color: Color(nsColor: .systemPurple.withSystemEffect(.pressed)), location: 0.5),
        ], startPoint: .top, endPoint: .bottom)
          .mask {
            Text("UI+")
              .font(.system(size: size * 0.4, weight: .heavy, design: .rounded))
              .offset(y: -size * 0.25)
          }
          .shadow(radius: 2)
      }
      .iconShape(size)
      .frame(width: size, height: size)
  }
}

#Preview {
  IconPreview { UIImprovementIconView(size: $0) }
}
