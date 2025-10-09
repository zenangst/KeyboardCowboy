import Bonzai
import Inject
import SwiftUI

struct GenericAppIconView: View {
  let size: CGFloat
  let primaryColor: Color
  let secondaryColor: Color

  init(primaryColor: Color = Color(nsColor: .systemBlue),
       secondaryColor: Color = Color(nsColor: .systemCyan),
       size: CGFloat)
  {
    self.size = size
    self.primaryColor = primaryColor
    self.secondaryColor = secondaryColor
  }

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          stops: [
            .init(color: primaryColor, location: 0.1),
            .init(color: primaryColor.blended(withFraction: 0.6, of: .black), location: 1.0),
          ],
          startPoint: .top,
          endPoint: .bottom,
        ),
      )
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: secondaryColor.blended(withFraction: 0.2, of: .white), location: 0.2),
          .init(color: primaryColor, location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
          .mask {
            Image(systemName: "app.fill")
              .font(Font.system(size: size * 0.9, weight: .thin, design: .rounded))
              .mask {
                Image(systemName: "app.dashed")
                  .font(Font.system(size: size * 0.9, weight: .thin, design: .rounded))

                Image(systemName: "pencil.and.scribble")
                  .font(Font.system(size: size * 0.52, weight: .regular, design: .rounded))
                  .rotationEffect(.degrees(-19))
                  .offset(x: -size * 0.230, y: size * 0.0_86)

                Image(systemName: "pencil")
                  .font(Font.system(size: size * 0.50, weight: .regular, design: .rounded))
                  .rotationEffect(.degrees(45))
                  .offset(y: size * 0.07)

                Image(systemName: "applepencil.gen1")
                  .font(Font.system(size: size * 0.50, weight: .regular, design: .rounded))
                  .rotationEffect(.degrees(-68))
                  .offset(x: size * 0.10)
              }
          }
          .shadow(color: primaryColor.blended(withFraction: 0.4, of: .black), radius: 2, y: 1)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  IconPreview { GenericAppIconView(size: $0) }
}
