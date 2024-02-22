import SwiftUI

struct ModifierKeyIcon: View {
  @Environment(\.colorScheme) var colorScheme
  let key: ModifierKey
  let alignment: Alignment
  @Binding var glow: Bool
  private let animation = Animation
    .easeInOut(duration: 1.25)
    .repeatForever(autoreverses: true)


  init(key: ModifierKey, 
       alignment: Alignment? = nil,
       glow: Binding<Bool> = .constant(false)) {
    self.key = key
    _glow = glow

    if let alignment = alignment {
      self.alignment = alignment
    } else {
      self.alignment = key == .capsLock ? .bottomLeading
        : key == .shift
        ? .bottomLeading : .topTrailing
    }
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        KeyBackgroundView(isPressed: .constant(false), height: proxy.size.height)
          .background(
            RoundedRectangle(cornerRadius: proxy.size.height * 0.1)
              .stroke(glow
                      ? Color(.systemRed) .opacity(0.5)
                      : Color.clear, lineWidth: 2)
              .padding(-2)
          )

        Group {
        Text(key.keyValue)
          .font(Font.system(size: proxy.size.height * 0.23,
                            weight: .medium, design: .rounded))
        }
        .padding(6)
        .frame(width: proxy.size.width,
               height: proxy.size.height,
               alignment: alignment)

        if key == .function {
          Group {
            Image(systemName: "globe")
              .resizable()
              .frame(width: proxy.size.height * 0.2,
                     height: proxy.size.height * 0.2,
                     alignment: .bottomLeading)
              .offset(x: proxy.size.width * 0.1,
                      y: -proxy.size.width * 0.1)
          }
          .frame(width: proxy.size.width,
                 height: proxy.size.height,
                 alignment: .bottomLeading)
        }

        Text(key.writtenValue)
          .font(Font.system(size: proxy.size.height * 0.23, weight: .bold, design: .rounded))
          .frame(height: proxy.size.height, alignment: .bottom)
          .offset(y: -proxy.size.width * 0.065)
      }
      .foregroundColor(
        Color(.textColor)
          .opacity(0.66)
      )
      .onAppear {
        if glow {
          withAnimation(animation, { glow.toggle() })
        }
      }
    }
  }
}

struct ModifierKeyIcon_Previews: PreviewProvider {
  static let size: CGFloat = 64

  static var previews: some View {
    return HStack {
      ForEach(ModifierKey.allCases) { modifier in
        ModifierKeyIcon(key: modifier)
          .frame(width: {
            switch modifier {
            case .command, .shift, .capsLock:
              return size * 1.5
            default:
              return size
            }
          }(),
          height: size)
      }
    }.padding(5)
  }
}
