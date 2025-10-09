import SwiftUI

struct EnvironmentIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          stops: [
            .init(color: Color(nsColor: .systemGreen.blended(withFraction: 0.2, of: .yellow)!), location: 0.1),
            .init(color: Color(nsColor: .systemGreen.blended(withFraction: 0.6, of: .black)!), location: 1.0),
          ],
          startPoint: .top,
          endPoint: .bottom,
        ),
      )
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .systemGreen.blended(withFraction: 0.5, of: .yellow)!), location: 0.2),
          .init(color: Color(nsColor: .systemGreen.blended(withFraction: 0.1, of: .blue)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
          .mask {
            Image(systemName: "square.fill")
              .resizable()
              .frame(width: size * 0.9, height: size * 0.9)
              .mask {
                RoundedRectangle(cornerRadius: size * 0.15)
              }
              .offset(x: size * 0.01, y: size * 0.01)
          }
          .overlay(alignment: .center) {
            Text("env")
              .font(.system(size: size * 0.4, weight: .heavy, design: .monospaced))
              .offset(y: -size * 0.05)
          }
          .shadow(color: Color(nsColor: .systemGreen.blended(withFraction: 0.5, of: .black)!), radius: 2, y: 2)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  IconPreview { EnvironmentIconView(size: $0) }
}
