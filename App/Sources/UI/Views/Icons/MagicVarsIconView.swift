import SwiftUI

struct MagicVarsIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          stops: [
            .init(color: Color(nsColor: .systemOrange.blended(withFraction: 0.3, of: .systemOrange)!), location: 0.1),
            .init(color: Color(nsColor: .systemOrange.blended(withFraction: 0.6, of: .black)!), location: 1.0)
          ],
          startPoint: .top,
          endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .systemYellow.blended(withFraction: 0.5, of: .white)!), location: 0.2),
          .init(color: Color(nsColor: .systemOrange.blended(withFraction: 0.1, of: .yellow)!), location: 1.0),
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
          Text("var")
            .font(.system(size: size * 0.4, weight: .heavy, design: .monospaced))
            .offset(y: -size * 0.05)
        }
        .overlay(alignment: .bottomTrailing) {
          Image(systemName: "wand.and.stars")
            .resizable()
            .foregroundStyle(
              Color.white,
              Color(nsColor: .systemYellow.blended(withFraction: 0.5, of: .white)!))
            .frame(width: size * 0.6, height: size * 0.6)
        }
        .shadow(color: Color(nsColor: .systemOrange.blended(withFraction: 0.5, of: .black)!), radius: 2, y: 2)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    MagicVarsIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      MagicVarsIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        MagicVarsIconView(size: 64)
        MagicVarsIconView(size: 32)
        MagicVarsIconView(size: 16)
      }
    }
  }
  .padding()
}

