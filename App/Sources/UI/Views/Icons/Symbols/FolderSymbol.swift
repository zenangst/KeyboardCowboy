import SwiftUI
import Cocoa

struct FolderSymbol: View {
  private let inset: EdgeInsets = EdgeInsets.init(top: 0.075,
                                                  leading: 0.025,
                                                  bottom: 0.1,
                                                  trailing: 0.025)
  let cornerRadius: CGFloat
  let textColor: Color
  private let tabWidth: CGFloat = 0.4
  private let tabHeight: CGFloat = 0.0375

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Path { path in
          path.move(to: CGPoint(x: minWidth(proxy) + cornerRadius(proxy),
                                y: minHeight(proxy) + topOffset(proxy) - cornerRadius(proxy)))

          path.addRelativeArc(center: CGPoint(x: tabWidth(proxy) - cornerRadius(proxy),
                                              y: minHeight(proxy) + topOffset(proxy)),
                              radius: cornerRadius(proxy),
                              startAngle: Angle(degrees: -90),
                              delta: Angle(degrees: 90))

          path.addLine(to: CGPoint(x: tabWidth(proxy),
                                   y: minHeight(proxy) + tabHeight(proxy) + topOffset(proxy)))

          path.addLine(to: CGPoint(x: maxWidth(proxy) - cornerRadius(proxy),
                                   y: minHeight(proxy) + tabHeight(proxy) + topOffset(proxy)))

          path.addRelativeArc(center: CGPoint(x: maxWidth(proxy),
                                              y: minHeight(proxy) + tabHeight(proxy) + topOffset(proxy) + cornerRadius(proxy)),
                              radius: cornerRadius(proxy),
                              startAngle: Angle(degrees: -90),
                              delta: Angle(degrees: 90))

          path.addLine(to: CGPoint(x: maxWidth(proxy) + cornerRadius(proxy),
                                   y: maxHeight(proxy) - cornerRadius(proxy)))

          path.addRelativeArc(center: CGPoint(x: maxWidth(proxy),
                                              y: maxHeight(proxy)),
                              radius: cornerRadius(proxy),
                              startAngle: Angle(degrees: 0),
                              delta: Angle(degrees: 90))

          path.addLine(to: CGPoint(x: minWidth(proxy) + cornerRadius(proxy),
                                   y: maxHeight(proxy) + cornerRadius(proxy)))

          path.addRelativeArc(center: CGPoint(x: minWidth(proxy),
                                              y: maxHeight(proxy)),
                              radius: cornerRadius(proxy),
                              startAngle: Angle(degrees: 90),
                              delta: Angle(degrees: 90))

          path.addLine(to: CGPoint(x: minWidth(proxy) - cornerRadius(proxy),
                                   y: minHeight(proxy) + tabHeight(proxy) + topOffset(proxy) + cornerRadius(proxy)))

          path.addRelativeArc(center: CGPoint(x: minWidth(proxy),
                                              y: minHeight(proxy) + tabHeight(proxy) + topOffset(proxy) + cornerRadius(proxy)),
                              radius: cornerRadius(proxy),
                              startAngle: Angle(degrees: 180),
                              delta: Angle(degrees: 90))

          path.addRelativeArc(center: CGPoint(x: minWidth(proxy) + cornerRadius(proxy),
                                              y: minHeight(proxy) + topOffset(proxy)),
                              radius: cornerRadius(proxy),
                              startAngle: Angle(degrees: 180),
                              delta: Angle(degrees: 90))

        }
        .fill(gradient())
        .colorScheme(.light)

        Text("macOS")
          .foregroundColor(textColor)
          .contrast(0.5)
          .font(Font.system(size: proxy.size.width * 0.17, weight: .regular, design: .rounded))
          .offset(x: 0, y: tabHeight(proxy))
      }
    }
  }

  private func gradient() -> LinearGradient {
    LinearGradient(
      gradient: Gradient(
        stops: [
          .init(color: Color.white.opacity(0.2), location: 0.0),
          .init(color: Color(.windowBackgroundColor), location: 0.1),
          .init(color: Color.white, location: 0.125),
          .init(color: Color(.windowBackgroundColor), location: 0.145),
          .init(color: Color.white, location: 0.145),
          .init(color: Color(.gridColor).opacity(0.75), location: 1.0),
        ]),
      startPoint: .top,
      endPoint: .bottom
    )
  }

  private func maxWidth(_ proxy: GeometryProxy) -> CGFloat {
    proxy.size.width - (proxy.size.width * inset.leading) - cornerRadius(proxy)
  }

  private func maxHeight(_ proxy: GeometryProxy) -> CGFloat {
    proxy.size.height - (proxy.size.width * inset.bottom) - cornerRadius(proxy)
  }

  private func minWidth(_ proxy: GeometryProxy) -> CGFloat {
    (proxy.size.width * inset.leading) + cornerRadius(proxy)
  }

  private func minHeight(_ proxy: GeometryProxy) -> CGFloat {
    (proxy.size.height * inset.top) - (proxy.size.height * tabHeight)
  }

  //  private func inset(_ proxy: GeometryProxy) -> CGFloat { proxy.size.width * inset }
  private func cornerRadius(_ proxy: GeometryProxy) -> CGFloat { proxy.size.width * cornerRadius }
  private func tabWidth(_ proxy: GeometryProxy) -> CGFloat { proxy.size.width * tabWidth }
  private func tabHeight(_ proxy: GeometryProxy) -> CGFloat { proxy.size.height * tabHeight }
  private func topOffset(_ proxy: GeometryProxy) -> CGFloat { proxy.size.height * (tabHeight + cornerRadius) }
}

struct FolderSymbol_Previews: PreviewProvider {
  static var previews: some View {
    FolderSymbol(cornerRadius: 0.03, textColor: .black)
      .background(Color.black)
      .frame(width: 400, height: 400)
  }
}

extension CGPoint: @retroactive Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
  }
}
