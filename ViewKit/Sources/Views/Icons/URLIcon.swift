import SwiftUI

struct URLIcon: View {
  var foregroundColor: NSColor {
    NSColor(red:0.45, green:0.66, blue:0.28, alpha:1.00)
  }
  
  var backgroundColor: NSColor {
    NSColor(red:0.60, green:0.80, blue:0.47, alpha:1.00)
  }
  
  var body: some View {
    GeometryReader { proxy in
      ZStack {
        GeometryReader { proxy in
          Rectangle()
            .fill(Color(foregroundColor))
            .cornerRadius(7)
            .shadow(radius: 2, y: 2)
          Rectangle()
            .fill(Color(backgroundColor))
            .cornerRadius(6)
            .padding(1)
            .shadow(radius: 1, y: 2)
          Text("HTTP://")
            .foregroundColor(Color(foregroundColor))
            .font(
              Font.custom("Menlo", fixedSize: proxy.size.width * 0.20))
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

struct URLIcon_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    URLIcon()
      .frame(width: 128, height: 128)
  }
}
