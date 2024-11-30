import SwiftUI

struct KeyboardIconView: View {
  @Environment(\.colorScheme) var colorScheme
  let size: CGFloat
  let letter: String

  init(_ letter: String = "", size: CGFloat) {
    self.size = size
    self.letter = letter
  }

  var body: some View {
    Rectangle()
      .fill(Color(.textBackgroundColor))
      .overlay { iconOverlay().opacity(0.2) }
      .overlay {
        AngularGradient(stops: [
          .init(color: Color.clear, location: 0.0),
          .init(color: Color.white.opacity(0.2), location: 0.2),
          .init(color: Color.clear, location: 1.0),
        ], center: .bottomLeading)

        LinearGradient(stops: [
          .init(color: Color.white.opacity(0.1), location: 0),
          .init(color: Color.clear, location: 0.02),
        ], startPoint: .top, endPoint: .bottom)

        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.99),
          .init(color: Color(.windowBackgroundColor), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      }
      .overlay { iconBorder(size).opacity(0.5) }
      .overlay {
        Text(letter)
          .font(Font.system(size: size * 0.3, weight: .regular, design: .rounded))
          .allowsTightening(true)
          .minimumScaleFactor(0.2)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
      .drawingGroup()
//      .background(
//        Rectangle()
//          .fill(Color.black.opacity( colorScheme == .light ? 0.33 : 0.9 ))
//          .clipShape(RoundedRectangle(cornerRadius: size * 0.125))
//          .offset(x: 0, y: size * 0.025)
//          .scaleEffect(x: 0.95)
//          .blur(radius: 1)
//      )
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    KeyboardIconView("M", size: 192)
    VStack(alignment: .leading, spacing: 8) {
      KeyboardIconView("O", size: 128)
      HStack(alignment: .top, spacing: 8) {
        KeyboardIconView("L", size: 64)
        KeyboardIconView("L", size: 32)
        KeyboardIconView("Y", size: 16)
      }
    }
  }
  .padding()
}
