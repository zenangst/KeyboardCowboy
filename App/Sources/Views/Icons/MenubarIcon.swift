import SwiftUI

struct MenubarIcon: View {
  let color: Color
  let size: CGSize
  let offset: CGPoint
  let fontSize: CGFloat

  init(color: Color, size: CGSize) {
    self.color = color
    self.size = size
    self.offset = size.height == 11
      ? CGPoint(x: 0.2, y: 0.0)
      : CGPoint(x: 0.25, y: 0)

    self.fontSize = size.height == 11
      ? 4
      : 11
  }

  var body: some View {
    ZStack {
      ZStack {
      RoundedRectangle(cornerRadius: size.height * 0.2)
        .stroke(color.opacity(0.75), lineWidth: size.height == 11 ? 0.5 : 1)
        .scaleEffect(0.9)
      Text("⌘")
        .foregroundColor(color.opacity(0.75))
        .multilineTextAlignment(.center)
        .font(Font.system(size: fontSize,
                          weight: .light, design: .rounded))
        .offset(x: offset.x,
                y: offset.y)
      }
      .padding(2)
    }
    .frame(width: size.width, height: size.height, alignment: .center)
  }
}

struct MenubarIcon_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      HStack {
        MenubarIcon(color: Color.accentColor, size: CGSize(width: 11, height: 11))
        MenubarIcon(color: Color.accentColor, size: CGSize(width: 22, height: 22))
      }

      HStack {
        MenubarIcon(color: Color(.textColor), size: CGSize(width: 11, height: 11))
        MenubarIcon(color: Color(.textColor), size: CGSize(width: 22, height: 22))
      }
    }
  }
}
