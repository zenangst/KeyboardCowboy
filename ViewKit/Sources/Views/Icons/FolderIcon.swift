import SwiftUI

struct FolderIcon: View {
  var havelockBlue: NSColor {
    NSColor(red:0.31, green:0.51, blue:0.76, alpha:1.00)
  }

  var blueGray: NSColor {
    NSColor(red:0.42, green:0.62, blue:0.80, alpha:1.00)
  }

  var babyBlue: NSColor {
    NSColor(red:0.60, green:0.80, blue:0.95, alpha:1.00)
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      Text("")
        .frame(width: 57, height: 42)
        .background(RoundedCorners(tl: 0, tr: 0,
                                   bl: 4, br: 4)
                      .fill(
                        LinearGradient(
                                      gradient: Gradient(
                                        stops:
                                          [.init(color: Color(blueGray),
                                                 location: 0.33),
                                             .init(color: Color(havelockBlue), location: 1.0)]
                                      ),
                                      startPoint: .top,
                                      endPoint: .bottom)

                      ))
        .offset(x: 0, y: 2)

      Text("")
        .frame(width: 57, height: 1.5)
        .shadow(color: Color(blueGray), radius: 5, x: 0, y: -2)
        .background(RoundedCorners(tl: 4, tr: 4,
                                   bl: 0, br: 0)
                      .fill(Color(havelockBlue)))
        .offset(x: 0, y: 1.0)

      Text("")
        .frame(width: 27, height: 4)
        .background(RoundedCorners(tl: 4, tr: 8,
                                   bl: 0, br: 0)
                      .fill(
                        LinearGradient(
                                      gradient: Gradient(
                                        stops:
                                          [.init(color: Color(blueGray),
                                                 location: 0.33),
                                             .init(color: Color(havelockBlue), location: 1.0)]
                                      ),
                                      startPoint: .top,
                                      endPoint: .bottom)

                      ))
        .offset(x: 1, y: -3)
    }
    .frame(width: 57, height: 57)
  }
}

struct RoundedCorners: Shape {
    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.size.width
        let h = rect.size.height

        // Make sure we do not exceed the size of the rectangle
        let tr = min(min(self.tr, h/2), w/2)
        let tl = min(min(self.tl, h/2), w/2)
        let bl = min(min(self.bl, h/2), w/2)
        let br = min(min(self.br, h/2), w/2)

        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr,
                    startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)

        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br,
                    startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)

        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl,
                    startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)

        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                    startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)

        return path
    }
}

struct FolderIcon_Previews: PreviewProvider {
  static var previews: some View {
    HStack {
      AppsIcon()
      ScriptIcon()
      KeyboardIcon()
      FolderIcon()
      URLIcon()
    }
  }
}
