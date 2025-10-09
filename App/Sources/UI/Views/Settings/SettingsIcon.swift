import SwiftUI

struct SettingsIcon: View {
  let color: Color
  let symbolName: String

  init(_ nsColor: NSColor, symbolName: String) {
    color = Color(nsColor: nsColor)
    self.symbolName = symbolName
  }

  init(_ color: Color, symbolName: String) {
    self.color = color
    self.symbolName = symbolName
  }

  var body: some View {
    Image(systemName: symbolName)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: 16, height: 16)
      .padding(4)
      .background {
        LinearGradient(
          stops: [
            .init(color: color, location: 0),
            .init(color: color.blended(withFraction: 0.25, of: .black), location: 1),
          ],
          startPoint: .top,
          endPoint: .bottom,
        )
      }
      .overlay { iconOverlay() }
      .overlay { iconBorder(20) }
      .iconShape(36)
  }
}

#Preview {
  SettingsIcon(NSColor.systemPink, symbolName: "gear")
}
