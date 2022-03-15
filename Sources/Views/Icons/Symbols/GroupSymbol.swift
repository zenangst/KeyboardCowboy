import SwiftUI

struct GroupSymbol: View {
  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .center) {
        ZStack {
          HStack(spacing: 0) {
            groupIllustration(proxy.frame(in: .local).transform { rect in
              var rect = rect
              rect.size.width /= 2.0
              rect.size.height /= 2.0
              return rect
            }, color: .white)
            groupIllustration(proxy.frame(in: .local).transform { rect in
              var rect = rect
              rect.size.width /= 2.0
              rect.size.height /= 2.0
              return rect
            }, color: .white)
          }
          .frame(height: proxy.size.height, alignment: .center)
          .opacity(0.5)

          groupIllustration(proxy.frame(in: .local).transform { rect in
            var rect = rect
            rect.size.width /= 2.0
            rect.size.height /= 2.0
            return rect
          }, color: .white)
            .offset(x: 0, y: proxy.size.height / 5.0)

        }
        .offset(x: 0, y: -proxy.size.height / 10.0)
      }
    }
  }

  func groupIllustration(_ rect: CGRect, color: Color) -> some View {
    VStack(alignment: .center, spacing: 0) {
      Circle()
        .fill(color)
        .frame(width: rect.size.width / 2.0,
               height: rect.size.height / 2.0,
               alignment: .center)

      Path { path in
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2, startAngle: .degrees(0),
                    endAngle: .degrees(180), clockwise: true)

      }.fill(gradient(color))
    }.frame(width: rect.width, height: rect.height)
  }

  private func gradient(_ color: Color) -> LinearGradient {
    LinearGradient(
      gradient: Gradient(
        stops: [
          .init(color: color.opacity(0.2), location: 0.0),
          .init(color: color, location: 0.1),
          .init(color: color, location: 0.125),
          .init(color: color, location: 0.145),
          .init(color: color, location: 0.145),
          .init(color: color.opacity(0.75), location: 1.0),
        ]),
      startPoint: .top,
      endPoint: .bottom
    )
  }
}

private extension CGRect {
  func transform(_ handler: (CGRect) -> CGRect) -> Self {
    handler(self)
  }
}

struct GroupSymbol_Previews: PreviewProvider {
  static var previews: some View {
    GroupSymbol().frame(width: 128, height: 128)
  }
}
