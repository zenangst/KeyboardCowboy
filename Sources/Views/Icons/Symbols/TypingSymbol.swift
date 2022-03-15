import SwiftUI

struct TypingSymbol: View {
  private let lineWidth: CGFloat = 0.5
  let foreground: Color

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 4)
        .fill(Color.white)
        .padding(.vertical, 6)

      HStack(spacing: 4) {
        Circle()
          .fill(Color.clear)
          .background(Circle().fill(foreground).opacity(0.25))
        Circle()
          .fill(Color.clear)
          .background(Circle().fill(foreground).opacity(0.5))
        Circle()
          .fill(Color.clear)
          .background(Circle().fill(foreground).opacity(0.75))
      }.padding(.horizontal, 3)
    }
  }
}

struct TrafficSymbol_Previews: PreviewProvider {
  static var previews: some View {
    TypingSymbol(foreground: Color.accentColor)
  }
}
