import SwiftUI

struct ImprovementIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemOrange.blended(withFraction: 0.6, of: .black)!), location: 0.0),
          .init(color: Color(.systemYellow), location: 0.6),
          .init(color: Color(.systemRed.blended(withFraction: 0.6, of: .white)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
      )
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemOrange), location: 0.5),
          .init(color: Color(.systemRed.blended(withFraction: 0.3, of: .white)!), location: 1.0),
        ], startPoint: .topTrailing, endPoint: .bottomTrailing)
        .opacity(0.6)
      }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemRed.blended(withFraction: 0.3, of: .white)!), location: 0.2),
          .init(color: Color.clear, location: 0.8),
        ], startPoint: .topTrailing, endPoint: .bottomLeading)
      }
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay {
        Image(systemName: "swift")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: size * 0.8)
          .shadow(color: Color(.systemRed.blended(withFraction: 0.5, of: .black)!), radius: 10, y: 10)
      }
      .iconShape(size)
      .frame(width: size, height: size)
      .drawingGroup(opaque: true)
  }
}

#Preview {
  IconPreview { ImprovementIconView(size: $0) }
}

