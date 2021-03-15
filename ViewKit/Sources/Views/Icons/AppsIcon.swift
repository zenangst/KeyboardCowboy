import SwiftUI

struct AppsIcon: View {
  var body: some View {
    ZStack {
      app(Color(.systemRed))
        .rotationEffect(.degrees(-20))
        .offset(x: -20,
                y: -10)
        .opacity(0.4)
      app(Color(.systemOrange))
        .rotationEffect(.degrees(-10))
        .offset(x: -10,
                y: -10)
        .opacity(0.6)
      app(Color(.systemYellow))
        .opacity(0.8)
        .rotationEffect(.degrees(5))
        .offset(x: 0,
                y: -10)
    }
    .offset(x: 12,
            y: 8)
    .frame(width: 57, height: 57)
    .shadow(radius: 2, y: 2)
    .padding(8)
  }
  
  func app(_ color: Color) -> some View {
    Rectangle()
      .fill(color)
      .cornerRadius(10)
      .frame(width: 42, height: 42)
  }
}

struct AppsIcon_Previews: PreviewProvider {
  static var previews: some View {
    AppsIcon()
  }
}
