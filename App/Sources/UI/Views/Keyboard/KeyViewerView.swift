import Bonzai
import Inject
import SwiftUI

@MainActor
final class KeyViewerPublisher: ObservableObject {
  @Published var modifiers: [ModifierKey]
  @Published var keystrokes: [Keystroke]

  init(keystrokes: [Keystroke] = [], modifiers: [ModifierKey] = []) {
    self.keystrokes = keystrokes
    self.modifiers = modifiers
  }
}

struct Keystroke: Hashable {
  let key: String
  var iterations: Int = 1
}

struct KeyViewerView: View {
  @ObserveInjection var inject
  @ObservedObject private var publisher: KeyViewerPublisher

  init(publisher: KeyViewerPublisher) {
    self.publisher = publisher
  }

  var body: some View {
    VStack(spacing: 2) {
      Text(createKeyStokeString(publisher.keystrokes))
        .lineLimit(1)
        .font(Font.system(size: 128, weight: .semibold, design: .rounded))
        .minimumScaleFactor(0.001)
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 8)
        .padding(.top, 8)

      ZenDivider(.horizontal)

      GeometryReader { proxy in
        let totalWidth = proxy.size.width
        let spacing: CGFloat = 8
        let largerKeyRatio: CGFloat = 1.3
        let smallerKeyRatio: CGFloat = 1.0
        let totalRatio = (largerKeyRatio * 2) + (smallerKeyRatio * 3)
        let keyWidth = (totalWidth - spacing * 4) / totalRatio
        let largerKeyWidth = keyWidth * largerKeyRatio
        let smallerKeyWidth = keyWidth * smallerKeyRatio
        let keyHeight = smallerKeyWidth

        if proxy.size.width > 0 {
          HStack(spacing: spacing) {
            ModifierKeyIcon(key: .function, glowColor: .white, glow: .readonly {
              publisher.modifiers.contains(.function)
            })
            .frame(width: smallerKeyWidth, height: keyHeight)
            ModifierKeyIcon(key: .leftShift, glowColor: .white, glow: .readonly {
              publisher.modifiers.contains(.leftShift) || publisher.modifiers.contains(.rightShift)
            })
            .frame(width: largerKeyWidth, height: keyHeight)
            ModifierKeyIcon(key: .leftControl, glowColor: .white, glow: .readonly {
              publisher.modifiers.contains(.leftControl) || publisher.modifiers.contains(.rightControl)
            })
            .frame(width: smallerKeyWidth, height: keyHeight)
            ModifierKeyIcon(key: .leftOption, glowColor: .white, glow: .readonly {
              publisher.modifiers.contains(.leftOption) || publisher.modifiers.contains(.rightOption)
            })
            .frame(width: smallerKeyWidth, height: keyHeight)
            ModifierKeyIcon(key: .leftCommand, glowColor: .white, glow: .readonly {
              publisher.modifiers.contains(.leftCommand) || publisher.modifiers.contains(.rightCommand)
            })
            .frame(width: largerKeyWidth, height: keyHeight)
          }
          .frame(maxHeight: .infinity, alignment: .bottom)
        }
      }
      .padding([.horizontal, .bottom], 8)
    }
    .frame(minWidth: 256, minHeight: 96, alignment: .bottom)
    .background(
      ZStack {
        ZenVisualEffectView(material: .hudWindow)
          .mask {
            LinearGradient(
              stops: [
                .init(color: .black, location: 0),
                .init(color: .clear, location: 1),
              ],
              startPoint: .top,
              endPoint: .bottom,
            )
          }
        ZenVisualEffectView(material: .contentBackground)
          .mask {
            LinearGradient(
              stops: [
                .init(color: .black.opacity(0.5), location: 0),
                .init(color: .black, location: 0.75),
              ],
              startPoint: .top,
              endPoint: .bottom,
            )
          }
      },
    )
    .ignoresSafeArea(.all)
    .frame(maxWidth: 420)
    .enableInjection()
  }

  private func createKeyStokeString(_ keystrokes: [Keystroke]) -> String {
    if keystrokes.isEmpty { return " " }
    var newValue = ""
    for keystroke in keystrokes {
      if keystroke.iterations > 1 {
        newValue += "\(keystroke.key)ˣ\(keystroke.iterations)"
      } else {
        newValue += keystroke.key
      }
    }

    return newValue
  }
}

#Preview {
  KeyViewerView(publisher: KeyViewerPublisher())
    .frame(width: 256, height: 128)
}
