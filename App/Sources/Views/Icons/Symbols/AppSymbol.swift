import SwiftUI

struct AppSymbol: View {
  @Environment(\.colorScheme) var colorScheme
  private var invertedColorScheme: ColorScheme {
    colorScheme == .dark ? .light : .dark
  }

  var body: some View {
    appOutline()
      .cornerRadius(8.0)
      .padding()
  }

  @ViewBuilder
  func appOutline() -> some View {
    ZStack {
//      GeometryReader { proxy in
//        RoundedRectangle(cornerRadius: 8)
//          .stroke(Color.white)
//        // Horizontal lines
//
//        Path { path in
//          path.move(to: CGPoint(x: 2, y: 2))
//          path.addLine(to: CGPoint(x: proxy.size.width - 2,
//                                   y: proxy.size.height - 2))
//        }.stroke(Color.white.opacity(0.6), lineWidth: 0.75)
//
//        Path { path in
//          path.move(to: CGPoint(x: 2, y: proxy.size.width - 2))
//          path.addLine(to: CGPoint(x: proxy.size.width - 2,
//                                   y: 2))
//        }.stroke(Color.white.opacity(0.6), lineWidth: 0.75)
//
//        Path { path in
//          path.move(to: CGPoint(x: 0, y: proxy.size.height * 0.25))
//          path.addLine(to: CGPoint(x: proxy.size.width,
//                                   y: proxy.size.height * 0.25))
//        }.stroke(Color.white.opacity(0.6), lineWidth: 0.75)
//
//        Path { path in
//          path.move(to: CGPoint(x: 0, y: proxy.size.height * 0.5))
//          path.addLine(to: CGPoint(x: proxy.size.width,
//                                   y: proxy.size.height * 0.5))
//        }.stroke(Color.white.opacity(0.6), lineWidth: 0.75)
//
//        Path { path in
//          path.move(to: CGPoint(x: 0, y: proxy.size.height * 0.75))
//          path.addLine(to: CGPoint(x: proxy.size.width,
//                                   y: proxy.size.height * 0.75))
//        }.stroke(Color.white.opacity(0.6), lineWidth: 0.75)
//
//        // Vertical lines
//
//        Path { path in
//          path.move(to: CGPoint(x: proxy.size.height * 0.25, y: 2))
//          path.addLine(to: CGPoint(x: proxy.size.height * 0.25,
//                                   y: proxy.size.height))
//        }.stroke(Color.white.opacity(0.6), lineWidth: 0.75)
//
//        Path { path in
//          path.move(to: CGPoint(x: proxy.size.height * 0.5, y: 2))
//          path.addLine(to: CGPoint(x: proxy.size.height * 0.5,
//                                   y: proxy.size.height))
//        }.stroke(Color.white.opacity(0.6), lineWidth: 0.75)
//
//        Path { path in
//          path.move(to: CGPoint(x: proxy.size.height * 0.75, y: 2))
//          path.addLine(to: CGPoint(x: proxy.size.height * 0.75,
//                                   y: proxy.size.height))
//        }.stroke(Color.white.opacity(0.6), lineWidth: 0.75)
//      }

      Circle()
        .stroke(Color.white, lineWidth: 0.75)
        .frame(width: 30, height: 30)
        .opacity(0.6)

      Circle()
        .stroke(Color.white, lineWidth: 0.75)
        .frame(width: 24, height: 24)
        .opacity(0.4)

      Circle()
        .stroke(Color.white, lineWidth: 0.75)
        .frame(width: 12, height: 12)
        .opacity(0.4)

    }
  }
}

struct AppSymbol_Previews: PreviewProvider {
  static var previews: some View {
      ZStack {
        AppSymbol()
          .background(Color.red)
      }
      .padding()
      .frame(width: 64, height: 64)
    }
}
