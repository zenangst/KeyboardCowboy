import Bonzai
import SwiftUI

struct GenericAppIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          stops: [
            .init(color: Color(nsColor: .systemBlue), location: 0.1),
            .init(color: Color(nsColor: .systemBlue.blended(withFraction: 0.6, of: .black)!), location: 1.0)
          ],
          startPoint: .top,
          endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .white), location: 0.2),
          .init(color: Color(nsColor: .systemBlue.blended(withFraction: 0.1, of: .white)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
        .mask {
          Image(systemName: "app.dashed")
            .font(Font.system(size: size * 1.1, weight: .thin, design: .rounded))


          Image(systemName: "applepencil.gen1")
            .font(Font.system(size: size * 0.65, weight: .bold, design: .rounded))
            .rotationEffect(.degrees(-22))
            .offset(x: -size * 0.17)
            .opacity(0.75)

          Image(systemName: "paintbrush.pointed.fill")
            .font(Font.system(size: size * 0.6, weight: .ultraLight, design: .rounded))
            .rotationEffect(.degrees(-70))
            .offset(x: size * 0.18, y: size * 0.025)
            .opacity(0.75)

          Image(systemName: "ruler.fill")
            .resizable()
            .font(Font.system(size: size * 0.4, weight: .ultraLight, design: .rounded))
            .frame(width: size * 0.65, height: size * 0.175)
            .offset(y: size * 0.05)
            .opacity(0.92)
        }
        .shadow(color: Color(nsColor: .systemBlue.blended(withFraction: 0.4, of: .black)!), radius: 2, y: 1)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  VStack {
    HStack(alignment: .top, spacing: 8) {
      GenericAppIconView(size: 192)
      VStack(alignment: .leading, spacing: 8) {
        GenericAppIconView(size: 128)
        HStack(alignment: .top, spacing: 8) {
          GenericAppIconView(size: 64)
          GenericAppIconView(size: 32)
          GenericAppIconView(size: 16)
        }
      }
    }

    HStack(alignment: .top, spacing: 8) {
      GenericAppIconView(size: 192)
      VStack(alignment: .leading, spacing: 8) {
        GenericAppIconView(size: 128)
        HStack(alignment: .top, spacing: 8) {
          GenericAppIconView(size: 64)
          GenericAppIconView(size: 32)
          GenericAppIconView(size: 16)
        }
      }
    }
  }
  .padding()
}
