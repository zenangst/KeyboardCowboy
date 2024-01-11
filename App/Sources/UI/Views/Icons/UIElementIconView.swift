import Inject
import SwiftUI

struct UIElementIconView: View {
  let strokeColor = Color(nsColor: NSColor(red:0.88, green:0.69, blue:0.24, alpha:1.00))
  let fillColor = Color(.systemYellow)
  let darkColor = Color(.systemGray)

  var body: some View {
    Canvas(rendersAsynchronously: true) {
      context,
      size in
      let lineWidth: CGFloat = 0.0 * size.width

      do {
        let path = Path { path in
          path.move(to: .init(x: size.width * 0.01,
                              y: (size.width * 0.220) + lineWidth / 2))
          path.addLine(to: .init(x: size.width * 0.365,
                                 y: size.height * 0.460))
          path.addLine(to: .init(x: size.width * 0.365,
                                 y: size.height - lineWidth))
          path.addLine(to: .init(x: size.width * 0.01,
                                 y: size.height * 0.562))
          path.closeSubpath()
        }
        context.fill(
          path,
          with: .linearGradient(
            Gradient(colors: [fillColor, strokeColor.opacity(0.75)]),
            startPoint: .init(x: size.width / 2, y: size.height / 2),
            endPoint: .init(x: 0, y: size.height / 2)
          ),
          style: FillStyle()
        )
      }

      do {
        let path = Path { path in
          path.move(to: .init(x: size.width * 0.01, y: (size.height * 0.167) - lineWidth))
          path.addLine(to: .init(x: size.width * 0.57,
                                 y: lineWidth))
          path.addLine(to: .init(x: size.width - lineWidth,
                                 y: size.height * 0.180))
          path.addLine(to: .init(x: size.width * 0.390 - lineWidth,
                                 y: size.height * 0.415 - lineWidth))
          path.closeSubpath()
        }
        context.fill(
          path,
          with: .linearGradient(
            Gradient(colors: [strokeColor.opacity(0.75), fillColor]),
            startPoint: .init(x: 0, y: 0),
            endPoint: .init(x: size.width / 4, y: size.height / 2)
          ),
          style: FillStyle()
        )
      }

      do {
        let path = Path { path in
          path.move(to: .init(x: size.width * 0.416 + lineWidth, y: size.height * 0.465))
          path.addLine(to: .init(x: size.width - lineWidth / 2, y: size.height * 0.235 + lineWidth))
          path.addLine(to: .init(x: size.width * 0.95 - lineWidth / 2, y: size.height * 0.650 + lineWidth))
          path.addLine(to: .init(x: size.width * 0.415 + lineWidth, y: size.height - lineWidth / 2))
          path.closeSubpath()
        }
        context.fill(
          path,
          with: .linearGradient(
            Gradient(colors: [fillColor, strokeColor.opacity(0.75)]),
            startPoint: .init(x: 0, y: 0),
            endPoint: .init(x: size.width / 4, y: size.height)
          ),
          style: FillStyle()
        )
      }
    }
    .enableInjection()
  }
}

#Preview {
  let canvas = CGSize(width: 1024, height: 1024)
  return UIElementIconView()
    .frame(width: canvas.width, height: canvas.height)
    .padding()
}

#Preview {
  let canvas = CGSize(width: 32, height: 32)
  return UIElementIconView()
    .frame(width: canvas.width, height: canvas.height)
    .padding()
}

