import SwiftUI

struct KeyboardIcon: View {
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
              .font(
                Font.custom("Menlo", fixedSize: proxy.size.width * 0.28))
          }
          .frame(width: proxy.size.width, alignment: .trailing)
          .offset(x: -proxy.size.width * 0.065,
                  y: proxy.size.width * 0.065)

          Group {
            Text("command").font(
              Font.custom("Menlo",fixedSize: proxy.size.width * 0.18))
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

struct KeyboardIcon_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardIcon()
      .frame(width: 128, height: 128)
  }
}
