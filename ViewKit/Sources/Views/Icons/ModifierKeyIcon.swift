import SwiftUI
import ModelKit

struct ModifierKeyIcon: View, KeyView {
  let key: ModifierKey

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        keyBackgroundView(proxy)

        Group {
        Text(key.keyValue)
          .font(Font.system(size: proxy.size.height * 0.23,
                            weight: .medium, design: .rounded))
        }
          .frame(width: proxy.size.width,
                 height: proxy.size.height,
                 alignment: key == .shift
                  ? .bottomLeading : .topTrailing)
          .offset(x: key == .shift
                    ? proxy.size.width * 0.065
                    : -proxy.size.width * 0.085,
                  y: key == .shift
                    ? -proxy.size.width * 0.045
                    : proxy.size.width * 0.085)

        if key == .function {
          Group {
            Image(systemName: "globe")
              .resizable()
              .frame(width: proxy.size.height * 0.25,
                     height: proxy.size.height * 0.25,
                     alignment: .bottomLeading)
              .offset(x: proxy.size.width * 0.085,
                      y: -proxy.size.width * 0.085)
          }
          .frame(width: proxy.size.width,
                 height: proxy.size.height,
                 alignment: .bottomLeading)
        }

        Text(key.writtenValue)
          .font(Font.system(size: {
            switch key {
            case .command:
              return proxy.size.width * 0.18
            default:
              return proxy.size.width * 0.25
            }
          }(), weight: .regular, design: .rounded))
          .frame(height: proxy.size.height, alignment: .bottom)
          .offset(y: -proxy.size.width * 0.065)
      }
      .foregroundColor(
        Color(.textColor)
          .opacity(0.5)
      )
    }
  }
}

struct ModifierKeyIcon_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static let size: CGFloat = 64

  static var testPreview: some View {
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
