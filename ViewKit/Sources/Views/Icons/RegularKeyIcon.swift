import SwiftUI
import ModelKit

protocol KeyView {}

extension KeyView {
  @ViewBuilder
  func keyBackgroundView(_ proxy: GeometryProxy) -> some View {
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

struct RegularKeyIcon: View, KeyView {
  var letter: String
  private let animation = Animation
    .easeInOut(duration: 1.5)
    .repeatForever(autoreverses: true)
  @State var glow: Bool

  init(letter: String, glow: Bool = false) {
    self.letter = letter.uppercased()
    self._glow = .init(initialValue: glow)
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        keyBackgroundView(proxy)
          .foregroundColor(Color(.textColor).opacity(0.5))
        Text(letter)
          .font(Font.system(size: proxy.size.width * 0.3, weight: .regular, design: .rounded))
          .foregroundColor(.clear)
          .overlay(
            Rectangle()
              .foregroundColor(glow
                                ? Color.accentColor .opacity(0.5)
                                : Color(.textColor).opacity(0.5))
              .mask(
                Text(letter)
                  .font(Font.system(size: proxy.size.width * 0.3, weight: .regular, design: .rounded))
              )
          )
          .shadow(color:
                    Color(.controlAccentColor).opacity(glow ? 1.0 : 0.0),
                  radius: 1,
                  y: glow ? 0 : 2
          )
          .aspectRatio(contentMode: .fill)
          .frame(alignment: .center)
          .padding(.horizontal, proxy.size.width * 0.2)
      }.onAppear {
        if glow {
          withAnimation(animation, { glow.toggle() })
        }
      }
    }
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
      RegularKeyIcon(letter: "o", glow: true).frame(width: 80, height: 80)
    }.padding(3)
  }
}
