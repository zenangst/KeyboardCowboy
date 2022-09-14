import SwiftUI

protocol KeyView {
  var colorScheme: ColorScheme { get }
}

extension KeyView {
  @ViewBuilder
  func keyBackgroundView(_ height: CGFloat) -> some View {
    ZStack {
      Rectangle()
        .fill(Color.black.opacity( colorScheme == .light ? 0.3 : 0.9 ))
        .cornerRadius(height * 0.1)
        .offset(x: 0, y: 1)
        .blur(radius: 2)
        .scaleEffect(CGSize(width: 0.99, height: 1.0))

      Rectangle()
        .fill(Color.black.opacity( colorScheme == .light ? 0.33 : 0.9 ))
        .cornerRadius(height * 0.1)
        .offset(x: 0, y: height * 0.025)
        .blur(radius: 1.0)
        .scaleEffect(CGSize(width: 0.95, height: 1.0))

      Rectangle()
        .fill(Color(.windowFrameTextColor))
        .cornerRadius(height * 0.1)
        .opacity(0.25)
      Rectangle()
        .fill(Color(.windowBackgroundColor))
        .cornerRadius(height * 0.1)
        .padding(0.1)
    }
  }
}

public struct RegularKeyIcon: View, KeyView {
  @Environment(\.colorScheme) var colorScheme
  @State var letters: [Letter]
  var width: CGFloat
  var height: CGFloat
  var alignment: Alignment
  private let animation = Animation
    .easeInOut(duration: 1.5)
    .repeatForever(autoreverses: true)
  @Binding var glow: Bool

  public init(letters: [String],
              width: CGFloat = 32,
              height: CGFloat = 32,
              alignment: Alignment = .center,
              glow: Binding<Bool> = .constant(false)) {
    _letters =  .init(initialValue: letters.compactMap({ Letter(string: $0.uppercased()) }))
    self.width = width
    self.height = height
    self.alignment = alignment
    self._glow = glow
  }

  public init(letter: String ...,
              width: CGFloat = 32,
              height: CGFloat = 32,
              alignment: Alignment = .center,
              glow: Binding<Bool> = .constant(false)) {
    self.init(letters: letter,
              width: width, height: height,
              alignment: alignment, glow: glow)
  }

  public var body: some View {
    letter(height: height)
      .fixedSize(horizontal: true, vertical: true)
      .frame(minWidth: width, maxWidth: .infinity, alignment: alignment)
      .background(keyBackgroundView(height)
                    .foregroundColor(Color(.textColor).opacity(0.66)))
      .onAppear {
        if glow {
          withAnimation(animation, { glow.toggle() })
        }
      }
  }

  func letter(height: CGFloat) -> some View {
    VStack {
      ForEach(letters) { letter in
        Text(letter.string)
          .font(Font.system(size: height * 0.3, weight: .regular, design: .rounded))
          .foregroundColor(.clear)
          .padding([.leading, .trailing])
          .overlay(
            Rectangle()
              .foregroundColor(glow
                                ? Color.accentColor .opacity(0.5)
                                : Color(.textColor).opacity(0.66))
              .mask(
                Text(letter.string)
                  .font(Font.system(size: height * 0.3, weight: .regular, design: .rounded))
              )
          )
          .shadow(color:
                    Color(.controlAccentColor).opacity(glow ? 1.0 : 0.0),
                  radius: 1,
                  y: glow ? 0 : 2
          )
      }
    }
    .frame(height: height)
  }
}

struct RegularKeyIcon_Previews: PreviewProvider {
  static var previews: some View {
    HStack {
      RegularKeyIcon(letter: "h", height: 80).frame(width: 80, height: 80)
      RegularKeyIcon(letter: "e", height: 80).frame(width: 80, height: 80)
      RegularKeyIcon(letter: "l", height: 80).frame(width: 80, height: 80)
      RegularKeyIcon(letter: "l", height: 80).frame(width: 80, height: 80)
      RegularKeyIcon(letter: "o", height: 80, glow: .constant(true)).frame(width: 80, height: 80)
    }
    .padding(3)
  }
}
