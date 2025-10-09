import SwiftUI

public struct RegularKeyIcon: View {
  @State private var isPressed: Bool = false
  private var letters: [Letter]
  private var width: CGFloat
  private var height: CGFloat
  private var alignment: Alignment
  private let animation = Animation
    .easeInOut(duration: 1.25)
    .repeatForever(autoreverses: true)
  @Binding var glow: Bool

  public init(letters: [String],
              width: CGFloat = 32,
              height: CGFloat = 32,
              alignment: Alignment = .center,
              glow: Binding<Bool> = .constant(false))
  {
    self.letters = letters.map { Letter(string: $0.uppercased()) }
    self.width = width
    self.height = height
    self.alignment = alignment
    _glow = glow
  }

  public init(letter: String ...,
              width: CGFloat = 32,
              height: CGFloat = 32,
              alignment: Alignment = .center,
              glow: Binding<Bool> = .constant(false))
  {
    self.init(letters: letter,
              width: width, height: height,
              alignment: alignment, glow: glow)
  }

  public var body: some View {
    ZStack {
      KeyBackgroundView(isPressed: $isPressed, height: height)
        .foregroundColor(Color(.textColor).opacity(0.66))
        .background(
          RoundedRectangle(cornerRadius: height * 0.1)
            .stroke(glow
              ? Color(.systemRed).opacity(0.5)
              : Color.clear, lineWidth: 2)
            .padding(-2),
        )
        .frame(
          minWidth: width,
          maxWidth: .infinity,
          minHeight: height,
          alignment: alignment,
        )
        .animation(.linear(duration: 0.1), value: isPressed)
        .onAppear {
          if glow {
            withAnimation(animation) { glow.toggle() }
          }
        }
      letter(height: height)
    }
  }

  func letter(height: CGFloat) -> some View {
    VStack {
      ForEach(letters) { letter in
        Text(letter.string)
          .font(Font.system(size: height * 0.3, weight: .bold, design: .rounded))
          .foregroundColor(.clear)
          .padding([.leading, .trailing], height * 0.3)
          .overlay(
            Rectangle()
              .foregroundColor(glow
                ? Color(.systemRed).opacity(0.5)
                : Color(.textColor).opacity(0.66))
              .mask(
                Text(letter.string)
                  .font(Font.system(size: height * 0.3, weight: .bold, design: .rounded)),
              ),
          )
          .compositingGroup()
          .shadow(color:
            Color(.controlAccentColor).opacity(glow ? 1.0 : 0.0),
            radius: 1,
            y: glow ? 0 : 2)
          .allowsHitTesting(false)
      }
    }
    .frame(height: height)
  }
}

struct RegularKeyIcon_Previews: PreviewProvider {
  static let size: CGFloat = 64
  static var previews: some View {
    HStack {
      RegularKeyIcon(letter: "h", height: size).frame(width: size, height: size)
      RegularKeyIcon(letter: "e", height: size).frame(width: size, height: size)
      RegularKeyIcon(letter: "l", height: size).frame(width: size, height: size)
      RegularKeyIcon(letter: "l", height: size).frame(width: size, height: size)
      RegularKeyIcon(letter: "o", height: size, glow: .constant(true)).frame(width: size, height: size)
    }
    .padding()
  }
}
