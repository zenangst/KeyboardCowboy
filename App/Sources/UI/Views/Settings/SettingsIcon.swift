import SwiftUI

struct SettingsIcon: View {
  let color: Color
  let symbolName: String

  init(_ nsColor: NSColor, symbolName: String) {
    self.color = Color(nsColor: nsColor)
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
        color
      }
      .overlay {
        iconOverlay()
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

#Preview {
  SettingsIcon(NSColor.systemPink, symbolName: "gear")
}
