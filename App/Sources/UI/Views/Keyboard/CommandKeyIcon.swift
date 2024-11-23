import SwiftUI

struct CommandKeyIcon: View {
  var body: some View {
    GeometryReader { proxy in
      let padding = proxy.size.width * 0.065
      KeyBackgroundView(isPressed: .readonly { false }, height: proxy.size.height * 0.75)
        .overlay(alignment: .topTrailing, content: {
          Text("⌘")
            .allowsTightening(true)
            .font(Font.system(size: proxy.size.width * 0.15, weight: .regular, design: .rounded))
            .frame(width: proxy.size.width, alignment: .trailing)
            .padding(.top, proxy.size.width * 0.065)
            .padding(.trailing, padding)
        })
        .overlay(alignment: .bottom, content: {
          Text("command")
            .allowsTightening(true)
            .frame(maxWidth: .infinity)
            .minimumScaleFactor(0.01)
            .lineLimit(1)
            .font(Font.system(size: 128, weight: .regular, design: .rounded))
            .padding(.bottom, proxy.size.width * 0.065)
            .padding([.leading, .trailing], padding)
        })
        .padding([.leading, .trailing], padding)
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
