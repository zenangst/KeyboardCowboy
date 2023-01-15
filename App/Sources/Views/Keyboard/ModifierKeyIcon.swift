import SwiftUI

struct ModifierKeyIcon: View, KeyView {
  @Environment(\.colorScheme) var colorScheme
  let key: ModifierKey
  let alignment: Alignment

  init(key: ModifierKey, alignment: Alignment? = nil) {
    self.key = key

    if let alignment = alignment {
      self.alignment = alignment
    } else {
      self.alignment = key == .shift
        ? .bottomLeading : .topTrailing
    }
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        keyBackgroundView(proxy.size.height)

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
          .font(Font.system(size: proxy.size.height * 0.23, weight: .regular, design: .rounded))
          .frame(height: proxy.size.height, alignment: .bottom)
          .offset(y: -proxy.size.width * 0.065)
      }
//      .fixedSize(horizontal: true, vertical: true)
      .foregroundColor(
        Color(.textColor)
          .opacity(0.66)
      )
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
            case .command, .shift:
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
