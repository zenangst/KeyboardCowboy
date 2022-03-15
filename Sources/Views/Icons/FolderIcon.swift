import SwiftUI

struct FolderIcon: View {
  @Environment(\.colorScheme) var colorScheme

  var havelockBlue: NSColor {
    var color = NSColor(red: 0.31, green: 0.51, blue:0.76, alpha: 1.00)
    if colorScheme == .dark {
      color = color.blended(withFraction: 0.25, of: NSColor.systemIndigo) ?? color
    }
    return color
  }

  var blueGray: NSColor {
    var color = NSColor(red: 0.42, green: 0.62, blue:0.80, alpha: 1.00)
    if colorScheme == .dark {
      color = color.blended(withFraction: 0.25, of: NSColor.systemIndigo) ?? color
    }
    return color
  }

  var babyBlue: NSColor {
    var color = NSColor(red: 0.60, green: 0.80, blue: 0.95, alpha: 1.00)
    if colorScheme == .dark {
      color = color.blended(withFraction: 0.25, of: NSColor.systemIndigo) ?? color
    }
    return color
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .center) {
        GeometryReader { proxy in
          Text("macOS")
            .foregroundColor(.white)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            .font(Font.system(size: proxy.size.width * 0.20, weight: .heavy, design: .rounded))
            .background(RoundedCorners(tl: 0, tr: proxy.size.width * 0.025,
                                       bl: proxy.size.width * 0.05,
                                       br: proxy.size.width * 0.05)
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
            .shadow(radius: 2)

          Text("")
            .frame(width: proxy.size.width, height: proxy.size.height * 0.025)
            .shadow(color: Color(blueGray), radius: 5, x: 0, y: -2)
            .background(RoundedCorners(tl: proxy.size.width * 0.05,
                                       tr: proxy.size.width * 0.05,
                                       bl: 0, br: 0)
                          .fill(Color(havelockBlue)))
            .offset(x: 0, y: -proxy.size.height * 0.0025)

          Text("")
            .frame(width: proxy.size.width * 0.47,
                   height: proxy.size.height * 0.1)
            .background(RoundedCorners(tl: proxy.size.width * 0.10,
                                       tr: proxy.size.width * 0.10,
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
            .offset(x: 0, y: -proxy.size.height * 0.1)
        }
      }
      .padding([.leading, .trailing], proxy.size.width * 0.075 )
      .padding([.top, .bottom], proxy.size.width * 0.2)
    }
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
      FolderIcon()
        .frame(width: 128, height: 128)
    }
  }
}
