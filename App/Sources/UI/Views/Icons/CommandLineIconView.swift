import SwiftUI

struct CommandLineIconView: View {
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
          Image(systemName: "command.square.fill")
            .resizable()
            .frame(width: size * 0.9, height: size * 0.9)
            .mask {
              RoundedRectangle(cornerRadius: size * 0.15)
            }
            .offset(x: size * 0.01)
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
    CommandLineIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      CommandLineIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        CommandLineIconView(size: 64)
        CommandLineIconView(size: 32)
        CommandLineIconView(size: 16)
      }
    }
  }
  .padding()
}

