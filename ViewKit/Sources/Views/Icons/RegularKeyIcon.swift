import SwiftUI
import ModelKit

struct RegularKeyIcon: View {
  var letter: String

  init(letter: String) {
    self.letter = letter.uppercased()
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        backgroundView(proxy)
        Text(letter)
          .font(Font.system(size: proxy.size.width * 0.3, weight: .regular, design: .rounded))
          .aspectRatio(contentMode: .fill)
          .frame(alignment: .center)
          .padding(.horizontal, proxy.size.width * 0.2)
      }
    }.foregroundColor(
      Color(.textColor)
        .opacity(0.5)
    )
  }

  @ViewBuilder
  func backgroundView(_ proxy: GeometryProxy) -> some View {
    Group {
      Rectangle()
        .fill(Color(.windowFrameTextColor))
        .cornerRadius(
          proxy.size.height * 0.15
        )
        .opacity(0.25)
      Rectangle()
        .fill(Color(.windowBackgroundColor))
        .cornerRadius(
          proxy.size.height * 0.1
        )
        .padding(proxy.size.width > 64 ? 2 : 1)
        .shadow(radius: 1, y: 2)
    }.shadow(radius: 2, y: 2)
  }
}

struct RegularKeyIcon_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    HStack {
      RegularKeyIcon(letter: "h").frame(width: 80, height: 80)
      RegularKeyIcon(letter: "e").frame(width: 80, height: 80)
      RegularKeyIcon(letter: "l").frame(width: 80, height: 80)
      RegularKeyIcon(letter: "l").frame(width: 80, height: 80)
      RegularKeyIcon(letter: "o").frame(width: 80, height: 80)
    }.padding(3)
  }
}
