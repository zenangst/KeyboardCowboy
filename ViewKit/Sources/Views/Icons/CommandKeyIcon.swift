import SwiftUI

struct CommandKeyIcon: View {
  var body: some View {
    GeometryReader { proxy in
      ZStack {
        GeometryReader { proxy in
          Group {
            Rectangle()
              .fill(Color(.windowFrameTextColor))
              .cornerRadius(7)
              .opacity(0.25)
            Rectangle()
              .fill(Color(.windowBackgroundColor))
              .cornerRadius(6)
              .padding(1)
              .shadow(radius: 1, y: 2)
          }.shadow(radius: 2, y: 2)

          Group {
            Text("⌘")
              .font(Font.system(size: proxy.size.width * 0.17, weight: .regular, design: .rounded))
          }
          .frame(width: proxy.size.width, alignment: .trailing)
          .offset(x: -proxy.size.width * 0.075,
                  y: proxy.size.width * 0.065)

          Group {
            Text("command")
              .font(Font.system(size: proxy.size.width * 0.19, weight: .regular, design: .rounded))
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

struct CommandKeyIcon_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    CommandKeyIcon()
      .frame(width: 128, height: 128)
  }
}
