import SwiftUI

struct BugFixIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemGreen.blended(withFraction: 0.6, of: .black)!), location: 0.0),
          .init(color: Color(.systemTeal), location: 0.6),
          .init(color: Color(.systemGreen.blended(withFraction: 0.6, of: .white)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
      )
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemGreen), location: 0.5),
          .init(color: Color(.systemGreen.blended(withFraction: 0.2, of: .white)!), location: 1.0),
        ], startPoint: .topTrailing, endPoint: .bottomTrailing)
        .opacity(0.6)
      }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemGreen.blended(withFraction: 0.3, of: .white)!), location: 0.2),
          .init(color: Color.clear, location: 0.8),
        ], startPoint: .topTrailing, endPoint: .bottomLeading)
      }
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay {
        ZStack {
          Image(systemName: "bandage.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size * 0.7)
            .rotationEffect(.degrees(90))
            .offset(x: size * -0.006, y: size * 0.004)
        }
        .compositingGroup()
        .shadow(color: Color(.systemGreen.blended(withFraction: 0.5, of: .black)!), radius: 10, y: 10)
        .fontWeight(.thin)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  IconPreview(content: { BugFixIconView(size: $0) })
}

