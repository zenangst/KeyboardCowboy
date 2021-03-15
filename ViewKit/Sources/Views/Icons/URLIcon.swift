import SwiftUI

struct URLIcon: View {
  var foregroundColor: NSColor {
    NSColor(red:0.45, green:0.66, blue:0.28, alpha:1.00)
  }
  
  var backgroundColor: NSColor {
    NSColor(red:0.60, green:0.80, blue:0.47, alpha:1.00)
  }
  
  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color(foregroundColor))
        .cornerRadius(6)
        .shadow(radius: 2, y: 2)
      Rectangle()
        .fill(Color(backgroundColor))
        .cornerRadius(6)
        .padding(1)
        .shadow(radius: 1, y: 2)
      Text("HTTP://")
        .foregroundColor(Color(foregroundColor))
        .font(Font.custom("Menlo", fixedSize: 10).bold())
        .offset(x: 0, y: 12)
    }
    .frame(width: 60, height: 48)
    .padding(8)
  }
}

struct URLIcon_Previews: PreviewProvider {
  static var previews: some View {
    URLIcon()
  }
}
