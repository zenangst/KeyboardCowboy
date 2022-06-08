import SwiftUI

struct CommandKeyIcon: View, KeyView {
  @Environment(\.colorScheme) var colorScheme
  var body: some View {
    GeometryReader { proxy in
      ZStack {
        GeometryReader { proxy in
          keyBackgroundView(proxy.size.height)

          Group {
            Text("⌘")
              .font(Font.system(size: proxy.size.width * 0.17, weight: .regular, design: .rounded))
          }
          .frame(width: proxy.size.width, alignment: .trailing)
          .offset(x: -proxy.size.width * 0.075,
                  y: proxy.size.width * 0.065)

          Group {
            Text("command")
              .font(Font.system(size: proxy.size.width * 0.17, weight: .regular, design: .rounded))
          }
          .frame(width: proxy.size.width, height: proxy.size.height,
                  alignment: .bottom)
          .offset(y: -proxy.size.width * 0.065)
        }
      }
      .padding([.leading, .trailing], proxy.size.width * 0.075 )
      .padding([.top, .bottom], proxy.size.width * 0.2)
    }
  }
}

struct CommandKeyIcon_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
    CommandKeyIcon()
      .frame(width: 128, height: 128)
    }.background(Color.white)
  }
}
