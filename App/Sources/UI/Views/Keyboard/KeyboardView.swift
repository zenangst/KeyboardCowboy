import SwiftUI

struct KeyboardView: View {
  let touchbar = false

  @ViewBuilder
  func row2_1(_ size: CGFloat) -> some View {
    RegularKeyIcon(letters: ["Q"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["W"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["E"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["R"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["T"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["Y"], width: size, height: size).frame(width: size, height: size)
  }

  @ViewBuilder
  func row2_2(_ size: CGFloat) -> some View {
    RegularKeyIcon(letters: ["U"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["I"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["O"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["P"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["Å"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["^"], width: size, height: size).frame(width: size, height: size)
  }

  @ViewBuilder
  func row3_1(_ size: CGFloat) -> some View {
    RegularKeyIcon(letters: ["A"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["S"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["D"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["F"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["G"], width: size, height: size).frame(width: size, height: size)
  }

  @ViewBuilder
  func row3_2(_ size: CGFloat) -> some View {
    RegularKeyIcon(letters: ["H"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["J"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["K"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["L"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["Ö"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["Ä"], width: size, height: size).frame(width: size, height: size)
  }

  @ViewBuilder
  func row4_1(_ size: CGFloat) -> some View {
    RegularKeyIcon(letters: [">"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["Z"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["X"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["C"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["V"], width: size, height: size).frame(width: size, height: size)
  }

  @ViewBuilder
  func row4_2(_ size: CGFloat) -> some View {
    RegularKeyIcon(letters: ["B"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["N"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["M"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: [";", ","], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: [":", "."], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["-", "_"], width: size, height: size).frame(width: size, height: size)
  }

  @ViewBuilder
  func row1_1(_ size: CGFloat) -> some View {
    RegularKeyIcon(letters: ["§", "'"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["!", "1"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["\"", "2"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["#", "3"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["$", "4"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["%", "5"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["&", "6"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["/", "7"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: ["\\(", "8"], width: size, height: size).frame(width: size, height: size)
    RegularKeyIcon(letters: [")", "9"], width: size, height: size).frame(width: size, height: size)
  }

  @ViewBuilder
  func row1_2(_ size: CGFloat) -> some View {
    RegularKeyIcon(letters: ["=", "0"], width: size, height: size)
      .frame(width: size, height: size)
    RegularKeyIcon(letters: ["?", "+"], width: size, height: size)
      .frame(width: size, height: size)
    RegularKeyIcon(letters: ["`", "´"], width: size, height: size)
      .frame(width: size, height: size)
  }

  let width: CGFloat

  var body: some View {
    ZStack(alignment: .trailing) {
      VStack(alignment: .leading, spacing: relative(8)) {
        if touchbar {
          HStack(spacing: relative(8)) {
            RegularKeyIcon(letter: "esc")
              .frame(width: relative(48), height: relative(28))

            HStack(spacing: 0) {
              HStack {
                RegularKeyIcon(letter: "►", height: relative(22))
                  .frame(width: relative(48), height: relative(22))
                  .colorScheme(.dark)
                  .opacity(0.6)
                RegularKeyIcon(letter: "◼︎", height: relative(22))
                  .frame(width: relative(48), height: relative(22))
                  .colorScheme(.dark)
                  .opacity(0.6)
              }

              HStack(spacing: 0) {
                RegularKeyIcon(letter: "<", height: relative(22))
                  .frame(width: relative(48), height: relative(22))
                  .colorScheme(.dark)
                  .opacity(0.6)

                RegularKeyIcon(letter: ">", height: relative(22))
                  .frame(width: relative(48), height: relative(22))
                  .colorScheme(.dark)
                  .opacity(0.6)
              }

              Spacer()
            }
            .colorScheme(.dark)
            .frame(height: relative(28))
            .padding(relative(2))
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
          }
        }

        HStack(spacing: relative(8)) {
          row1_1(relative(48))
          row1_2(relative(48))
          RegularKeyIcon(letters: ["", "⌫"],
                         width: relative(56),
                         height: relative(48),
                         alignment: .bottomTrailing)
            .frame(width: relative(74), height: relative(48))
        }

        HStack(alignment: .top, spacing: 0) {
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: relative(8)) {
              RegularKeyIcon(letters: [" ", "  ⇥"],
                             width: relative(60),
                             height: relative(48),
                             alignment: .bottomLeading)
                .frame(width: relative(72), height: relative(48))
              row2_1(relative(48))
              row2_2(relative(48))
            }

            Spacer().frame(height: relative(8))

            HStack(spacing: relative(8)) {
              RegularKeyIcon(letters: [" ∘", " ⇪"],
                             width: relative(72),
                             height: relative(48),
                             alignment: .leading)
                .frame(width: relative(84), height: relative(48))

              row3_1(relative(48))
              row3_2(relative(48))
              RegularKeyIcon(letters: ["*", "@"],
                             width: relative(48), height: relative(48))
                .frame(width: relative(48), height: relative(48))
            }
          }
          EnterKey(width: relative(48),
                   height: relative(48) + relative(48) + relative(8))
            .offset(CGSize(width: relative(-2),
                           height: relative(1)))
        }

        HStack(spacing: relative(8)) {
          ModifierKeyIcon(key: .leftShift)
            .frame(width: relative(68), height: relative(48))

          row4_1(relative(48))
          row4_2(relative(48))

          ModifierKeyIcon(key: .leftShift, alignment: .bottomTrailing)
            .frame(width: relative(48) + relative(48) + relative(16),
                   height: relative(48))
        }

        HStack(spacing: relative(8)) {
          ModifierKeyIcon(key: .function)
            .frame(width: relative(48), height: relative(48))
          ModifierKeyIcon(key: .leftControl)
            .frame(width: relative(48), height: relative(48))
          ModifierKeyIcon(key: .leftOption)
            .frame(width: relative(48), height: relative(48))
          ModifierKeyIcon(key: .leftCommand)
            .frame(width: relative(64), height: relative(48))

          RegularKeyIcon(letter: "",
                         height: relative(48))
            .frame(width: width * 0.33, height: relative(48))

          ModifierKeyIcon(key: .rightCommand, alignment: .topLeading)
            .frame(width: relative(64), height: relative(48))
          ModifierKeyIcon(key: .rightOption, alignment: .topLeading)
            .frame(width: relative(48), height: relative(48))

          VStack(spacing: 0) {
            Spacer().frame(width: relative(48),
                           height: relative(24))
            RegularKeyIcon(letter: "◀︎",
                           width: relative(48),
                           height: relative(24))
              .frame(width: relative(48), height: relative(24))
          }.frame(width: relative(48), height: relative(48))

          VStack(spacing: 0) {
            RegularKeyIcon(letter: "▲",
                           width: relative(48),
                           height: relative(24))
              .frame(width: relative(48), height: relative(24))
            RegularKeyIcon(letter: "▼",
                           width: relative(48),
                           height: relative(24))
              .frame(width: relative(48), height: relative(24))
          }

          VStack(spacing: 0) {
            Spacer().frame(height: relative(24))
            RegularKeyIcon(letter: "►",
                           width: relative(48),
                           height: relative(24))
              .frame(width: relative(48), height: relative(24))
          }.frame(width: relative(48), height: relative(48))
        }
      }
    }
    .padding(relative(16))
  }

  func relative(_ number: CGFloat) -> CGFloat {
    let standard: CGFloat = 800
    return ceil(number * ((width - number) / (standard - number)))
  }
}

struct KeyboardView_Previews: PreviewProvider {
  static var previews: some View {
//      KeyboardView(width: 320).previewDisplayName("320")
//      KeyboardView(width: 640).previewDisplayName("640")
    KeyboardView(width: 800)
      .previewDisplayName("800")
//      KeyboardView(width: 1024).previewDisplayName("1024")
  }
}
