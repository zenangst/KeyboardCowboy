import SwiftUI

struct AppToggle: View {
  enum Style {
    case regular
    case small

    var size: CGSize {
      switch self {
      case .regular:
        return CGSize(width: 38, height: 20)
      case .small:
        return CGSize(width: 22, height: 12)
      }
    }

    var circle: CGSize {
      switch self {
      case .regular:
        return CGSize(width: 19, height: 19)
      case .small:
        return CGSize(width: 11, height: 11)
      }
    }
  }

  @Environment(\.controlActiveState) var controlActiveState
  @Binding private var isOn: Bool
  private let onColor: Color
  private let style: Style
  private let titleKey: String
  private let onChange: (Bool) -> Void

  init(_ titleKey: String,
       onColor: Color = Color(nsColor: .controlColor),
       style: Style = .regular,
       isOn: Binding<Bool>,
       onChange: @escaping (Bool) -> Void = { _ in }) {
    _isOn = isOn
    self.onColor = onColor
    self.style = style
    self.titleKey = titleKey
    self.onChange = onChange
  }

  var body: some View {
    HStack(spacing: 4) {
      Text(titleKey)
      Button(action: {
        isOn.toggle()
        onChange(isOn)
      }, label: {
        Capsule()
          .fill(
            controlActiveState == .key
            ? isOn ? onColor : Color(nsColor: .controlColor)
            : Color(nsColor: .controlColor)
          )
          .overlay(alignment: isOn ? .trailing : .leading, content: {
            Circle()
              .frame(width: style.circle.width, height: style.circle.height)
              .overlay(
                Circle()
                  .stroke(Color(nsColor: .gray), lineWidth: 0.5)
              )
          })
          .animation(.default, value: isOn)
          .background(
            Capsule()
              .strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 1)
          )
          .frame(width: style.size.width, height: style.size.height)
      })
      .buttonStyle(.plain)
    }
  }
}



struct AppToggle_Previews: PreviewProvider {
  static var systemToggles: some View {
    VStack {
      Toggle(isOn: .constant(true), label: {
        Text("Default on")
      })
      .tint(Color(.systemGreen))
      Toggle(isOn: .constant(false), label: {
        Text("Default off")
      })
    }
  }

  static var previews: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top, spacing: 32) {
        VStack(alignment: .leading) {
          Text("System")
            .font(.headline)
          systemToggles
            .toggleStyle(.switch)
        }

        VStack(alignment: .leading) {
          Text("Regular")
            .font(.headline)
          AppToggle("Default on",
                    onColor: Color(.systemGreen),
                    style: .small,
                    isOn: .constant(true)) { _ in }
          AppToggle("Default off",
                    style: .small,
                    isOn: .constant(false)) { _ in }
        }

        VStack(alignment: .leading) {
          Text("Small")
            .font(.headline)
          AppToggle("Default on", style: .small, isOn: .constant(true)) { _ in }
          AppToggle("Default off", style: .small, isOn: .constant(false)) { _ in }
        }
      }
    }
    .padding()
  }
}
