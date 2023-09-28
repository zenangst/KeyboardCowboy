import SwiftUI

struct EnterKey: View {
  @Environment(\.colorScheme) var colorScheme
  let parameters = ShapeParameters()
  let width: CGFloat
  let height: CGFloat

  var body: some View {
    ZStack {
      shape(Color.black.opacity( colorScheme == .light ? 0.3 : 0.9 ),
            size: CGSize(width: width, height: height))
        .transform {
          $0.offset(x: 0, y: 1)
            .blur(radius: 2)
            .scaleEffect(CGSize(width: 0.99, height: 1.0))
        }

      shape(Color.black.opacity( colorScheme == .light ? 0.33 : 0.9 ),
            size: CGSize(width: width, height: height))
        .transform {
          $0.offset(x: 0, y: height * 0.005)
            .blur(radius: 1.0)
            .scaleEffect(CGSize(width: 0.95, height: 1.0))
        }

      shape(Color(.windowFrameTextColor),
            size: CGSize(width: width, height: height))
        .transform {
          $0.opacity(0.25)
        }

      shape(Color(.windowBackgroundColor),
            size: CGSize(width: width, height: height))

      Text("↩")
        .font(Font.system(size: height * 0.1, weight: .regular, design: .rounded))
        .frame(width: width, height: height, alignment: .trailing)
        .offset(x: -width * 0.155, y: -height * 0.155)
    }.frame(width: width, height: height)
  }

  func shape(_ color: Color, size: CGSize) -> some View {
    Rectangle()
      .fill(color)
      .mask(
        Path { path in
          parameters.segments(0.05).enumerated().forEach { offset, segment in
            if offset == 0 {
              path.move(to: CGPoint(x: ceil(width * segment.line.x),
                                    y: ceil(height * segment.line.y)))
            } else {
              path.addLine(to: CGPoint(x: width * segment.line.x, y: height * segment.line.y))
            }

            path.addQuadCurve(to: CGPoint(x: ceil(width * segment.curve.x),
                                          y: ceil(height * segment.curve.y)),
                              control: CGPoint(x: ceil(width * segment.control.x),
                                               y: ceil(height * segment.control.y)
                              ))
          }
        }
    )
  }

  let gradientStart = Color(red: 239.0 / 255, green: 120.0 / 255, blue: 221.0 / 255)
  let gradientEnd = Color(red: 239.0 / 255, green: 172.0 / 255, blue: 120.0 / 255)
}

struct EnterKey_Previews: PreviewProvider {
  static var previews: some View {
    EnterKey(width: 64, height: 128)
      .padding()
  }
}

struct ShapeParameters {
  struct Segment {
    let line: CGPoint
    let curve: CGPoint
    let control: CGPoint
  }

  func segments(_ cornerRadius: CGFloat) -> [Segment] {
    [
      Segment(
        line: CGPoint(x: 0.0, y: 0.0 + cornerRadius),
        curve: CGPoint(x: 0.0 + cornerRadius, y: 0.0),
        control: CGPoint(x: 0.0, y: 0.0)
      ),
      Segment(
        line: CGPoint(x: 1.0 - cornerRadius, y: 0.0),
        curve: CGPoint(x: 1.0, y: 0.0 + cornerRadius),
        control: CGPoint(x: 1.0, y: 0.0)
      ),
      Segment(
        line: CGPoint(x: 1.0, y: 1.0 - cornerRadius),
        curve: CGPoint(x: 1.0 - cornerRadius, y: 1.0),
        control: CGPoint(x: 1.0, y: 1.0)
      ),
      Segment(
        line: CGPoint(x: 0.25 + cornerRadius, y: 1.0),
        curve: CGPoint(x: 0.25, y: 1.0 - cornerRadius),
        control: CGPoint(x: 0.25, y: 1.0)
      ),
      Segment(
        line: CGPoint(x: 0.25,
                      y: 0.45 + cornerRadius),
        curve: CGPoint(x: 0.25 - cornerRadius,
                       y: 0.45),
        control: CGPoint(x: 0.25,
                         y: 0.45)
      ),
      Segment(
        line: CGPoint(x: 0.0 + cornerRadius, y: 0.45),
        curve: CGPoint(x: 0.0, y: 0.45 - cornerRadius),
        control: CGPoint(x: 0.0, y: 0.45)
      ),
    ]
  }
}
