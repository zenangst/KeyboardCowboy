import SwiftUI

struct MacroIconView: View {
  enum Kind {
    case record
    case remove
  }
  let kind: Kind
  let size: CGFloat

  init(_ kind: Kind, size: CGFloat) {
    self.kind = kind
    self.size = size
  }

  var body: some View {
    let color: NSColor = kind == .record
                      ? .systemCyan
                      : .systemYellow
    Rectangle()
      .fill(LinearGradient(
        stops: [
          .init(color: Color(nsColor: color), location: 0.1),
          .init(color: Color(nsColor: color.withSystemEffect(.disabled)), location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom))
      .overlay { iconBorder(size) }
      .overlay(alignment: .center) {
        backgroundShape(color: Color(nsColor: color))
          .scaleEffect(0.8)
          .rotation3DEffect(.degrees(30), axis: (x: 1.0, y: 0.0, z: 0.0))
          .offset(y: -size * 0.225)

        backgroundShape(color: Color(nsColor: color))
          .scaleEffect(0.9)
          .rotation3DEffect(.degrees(15), axis: (x: 1.0, y: 0.0, z: 0.0))
          .offset(y: -size * 0.125)

        Text("MACRO")
          .frame(minWidth: size * 0.9, minHeight: size * 0.4)
          .font(Font.system(size: size * 0.225, weight: .heavy, design: .rounded))
          .foregroundColor(Color(nsColor: color))
          .allowsTightening(true)
          .padding(size * 0.02)
          .overlay {
            RoundedRectangle(cornerRadius: size * 0.05)
              .fill(.black)
              .frame(width: size * 0.9, height: size * 0.025)
              .opacity(kind == .record ? 0 : 1)
          }
          .background {
            RoundedRectangle(cornerRadius: size * 0.05)
              .fill(Color(.textBackgroundColor))
              .overlay(overlay())
              .shadow(radius: 2, y: 2)
          }
      }
      .overlay(alignment: .bottomTrailing) {
        RoundedRectangle(cornerRadius: size * 0.05)
          .fill(Color(kind == .record ? .systemGreen : .systemRed))
          .overlay {
            Image(systemName: kind == .record ? "plus" : "minus")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .fontWeight(.heavy)
              .frame(width: size * 0.15, height: size * 0.15)
          }
          .overlay(content: {
            overlay()
              .mask(RoundedRectangle(cornerRadius: size * 0.05))
              .shadow(radius: 2)
          })
          .background {
            RoundedRectangle(cornerRadius: size * 0.05)
              .stroke(Color(.white).opacity(0.75), lineWidth: size * 0.0075)
              .offset(y: size * 0.015)
          }
          .frame(width: size * 0.25, height: size * 0.25)
          .offset(x: -size * 0.075, y: -size * 0.075)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
      .drawingGroup()
  }

  @ViewBuilder
  func overlay() -> some View {
    AngularGradient(stops: [
      .init(color: Color.clear, location: 0.0),
      .init(color: Color.white.opacity(0.2), location: 0.2),
      .init(color: Color.clear, location: 1.0),
    ], center: .bottomLeading)

    LinearGradient(stops: [
      .init(color: Color.white.opacity(0.2), location: 0),
      .init(color: Color.clear, location: 0.3),
    ], startPoint: .top, endPoint: .bottom)

    LinearGradient(stops: [
      .init(color: Color.clear, location: 0.8),
      .init(color: Color(.windowBackgroundColor).opacity(0.3), location: 1.0),
    ], startPoint: .top, endPoint: .bottom)
  }

  func backgroundShape(color: Color) -> some View {
    Rectangle()
      .fill(color)
      .overlay {
        RoundedRectangle(cornerRadius: size * 0.05)
          .stroke(Color(.textBackgroundColor), lineWidth: size * 0.0175)
      }
      .frame(width: size * 0.9, height: size * 0.4)
      .shadow(radius: 2, y: 2)
  }
}

#Preview {
  VStack(spacing: 0) {
    IconPreview { MacroIconView(.record, size: $0) }
    IconPreview { MacroIconView(.remove, size: $0) }
  }
}
