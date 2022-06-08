import SwiftUI

struct URLSymbol: View {
  var foregroundColor: NSColor {
    NSColor(red: 0.45, green: 0.66, blue: 0.28, alpha: 1.00)
  }

  var backgroundColor: NSColor {
    NSColor(red: 0.60, green: 0.80, blue: 0.47, alpha: 1.00)
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        GeometryReader { proxy in
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color.white, lineWidth: 0.5)
          Text("HTTP://")
            .foregroundColor(Color.white)
            .font(
              Font.custom("Menlo", fixedSize: proxy.size.width * 0.20))
            .frame(width: proxy.size.width, height: proxy.size.height,
                   alignment: .bottom)
            .offset(y: -proxy.size.width * 0.065)
        }
      }
      .padding([.top, .bottom], proxy.size.width * 0.2)
    }
  }
}

struct URLSymbol_Previews: PreviewProvider {
  static var previews: some View {
    URLSymbol()
      .frame(width: 128, height: 128)
  }
}
