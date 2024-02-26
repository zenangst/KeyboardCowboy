import SwiftUI

struct UserModeIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          stops: [
            .init(color: Color(nsColor: .systemBrown.blended(withFraction: 0.3, of: .systemOrange)!), location: 0.1),
            .init(color: Color(nsColor: .systemBrown.blended(withFraction: 0.6, of: .black)!), location: 1.0)
          ],
          startPoint: .top,
          endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .white), location: 0.2),
          .init(color: Color(nsColor: .systemBrown.blended(withFraction: 0.1, of: .white)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
        .mask {
          Image(systemName: "square.stack.3d.down.forward")
            .font(Font.system(size: size * 0.6, weight: .heavy, design: .rounded))
        }
        .shadow(color: Color(nsColor: .systemBrown.blended(withFraction: 0.4, of: .black)!), radius: 2, y: 1)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    UserModeIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      UserModeIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        UserModeIconView(size: 64)
        UserModeIconView(size: 32)
        UserModeIconView(size: 16)
      }
    }
  }
  .padding()
}

