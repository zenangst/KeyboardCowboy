import SwiftUI
import ModelKit

struct ModifierKeyIcon: View {
  let key: ModifierKey

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        GeometryReader { proxy in
          Group {
            Rectangle()
              .fill(Color(.windowFrameTextColor).opacity(0.55))
              .cornerRadius(
                proxy.size.height * 0.1
              )
              .opacity(0.25)
            Rectangle()
              .fill(Color(.windowBackgroundColor))
              .cornerRadius(
                proxy.size.height * 0.05
              )
              .padding(1.5)
              .shadow(radius: 1, y: 2)
          }.shadow(radius: 2, y: 2)

          Group {
            Text(key.keyValue)
              .font(Font.system(size: {
                switch key {
                case .command:
                  return proxy.size.height * 0.17
                default:
                  return proxy.size.height * 0.23
                }
              }(),
              weight: .medium, design: .rounded))
              .frame(width: proxy.size.width,
                     height: key == .shift ? proxy.size.height : nil,
                     alignment: key == .shift
                      ? .bottomLeading : .trailing)
              .offset(x: key == .shift
                        ? proxy.size.width * 0.065
                        : -proxy.size.width * 0.075,
                      y: key == .shift
                        ? -proxy.size.width * 0.045
                        : proxy.size.width * 0.065)
          }


          Group {
            if key == .function {
              Image(systemName: "globe")
                .resizable()
                .frame(width: proxy.size.height * 0.25,
                       height: proxy.size.height * 0.25,
                        alignment: .bottomLeading)
                .offset(x: proxy.size.width * 0.085,
                        y: -proxy.size.width * 0.085)
            }
          }.frame(width: proxy.size.width,
                  height: proxy.size.height,
                  alignment: .bottomLeading)

          Group {
            Text(key.writtenValue)
              .font(Font.system(size: {
                switch key {
                case .command:
                  return proxy.size.width * 0.18
                default:
                  return proxy.size.width * 0.25
                }
              }(), weight: .regular, design: .rounded))
          }
          .frame(width: proxy.size.width,
                 height: proxy.size.height,
                  alignment: .bottom)
          .offset(y: -proxy.size.width * 0.065)
        }
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
