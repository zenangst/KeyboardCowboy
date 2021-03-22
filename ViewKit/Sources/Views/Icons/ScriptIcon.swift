import SwiftUI

struct ScriptIcon: View {
  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        Rectangle()
          .fill(Color.gray)
          .cornerRadius(11)
        Rectangle()
          .fill(Color.black)
          .cornerRadius(10)
          .padding(1)
          .shadow(radius: 1, y: 2)
        Text(">_")
          .font(Font.custom(
                  "Menlo",
                  fixedSize: proxy.size.width * 0.20))
          .foregroundColor(.accentColor)
          .offset(x: proxy.size.width * 0.1,
                  y: proxy.size.height * 0.1)
      }
      .shadow(radius: 2, y: 2)
      .padding([.leading, .trailing], proxy.size.width * 0.075 )
      .padding([.top, .bottom], proxy.size.width * 0.095)
    }
  }
}

struct ScriptIcon_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    Group {
      ScriptIcon()
    }
    .background(Color.white)
    .frame(width: 128, height: 128)
  }
}
