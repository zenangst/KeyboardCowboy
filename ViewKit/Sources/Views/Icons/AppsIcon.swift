import SwiftUI

struct AppsIcon: View {
  var body: some View {
    GeometryReader { proxy in
      ZStack {
        app(Color(.systemRed))
          .rotationEffect(.degrees(-20))
          .offset(x: proxy.size.width * 0.2,
                  y: proxy.size.height * 0.20)
          .opacity(0.4)
        app(Color(.systemOrange))
          .rotationEffect(.degrees(-10))
          .offset(x: proxy.size.width * 0.30,
                  y: proxy.size.height * 0.20)
          .opacity(0.6)
        app(Color(.systemYellow))
          .opacity(0.8)
          .rotationEffect(.degrees(5))
          .offset(x: proxy.size.width * 0.40,
                  y: proxy.size.height * 0.25)
      }
      .shadow(radius: 2, y: 2)
    }
  }

  func app(_ color: Color) -> some View {
    GeometryReader { proxy in
      Rectangle()
        .fill(color)
        .cornerRadius(proxy.size.width * 0.1)
        .frame(width: proxy.size.width * 0.5,
               height: proxy.size.height * 0.5)
    }
  }
}

struct AppsIcon_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    AppsIcon()
      .frame(width: 128, height: 128)
  }
}
