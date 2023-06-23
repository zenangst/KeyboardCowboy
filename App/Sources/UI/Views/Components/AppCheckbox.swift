import SwiftUI

struct AppCheckbox: View {
  enum Style {
    case regular
    case small

    var size: CGSize {
      switch self {
      case .regular:
        return CGSize(width: 16, height: 16)
      case .small:
        return CGSize(width: 12, height: 12)
      }
    }

    var fontSize: CGFloat {
      switch self {
      case .regular:
        return 10
      case .small:
        return 8
      }
    }
  }

  @Binding private var isOn: Bool
  private let style: Style
  private let titleKey: String
  private let onChange: (Bool) -> Void

  init(_ titleKey: String,
       style: Style = .regular,
       isOn: Binding<Bool>,
       onChange: @escaping (Bool) -> Void = { _ in }) {
    _isOn = isOn
    self.style = style
    self.titleKey = titleKey
    self.onChange = onChange
  }

  var body: some View {
    HStack(spacing: 4) {
      Button(action: {
        isOn.toggle()
        onChange(isOn)
      }, label: {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(Color(nsColor: .controlColor))
          .overlay(content: {
            Image(systemName: "checkmark")
              .font(Font.system(size: style.fontSize, weight: .heavy))
              .opacity(isOn ? 1 : 0)
          })
          .frame(width: style.size.width, height: style.size.height)
      })
      .buttonStyle(.plain)
      Text(titleKey)
    }
  }
}

struct AppCheckbox_Previews: PreviewProvider {
  static var systemToggles: some View {
    VStack {
      Toggle(isOn: .constant(true), label: {
        Text("Default on")
      })
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
        }

        VStack(alignment: .leading) {
          Text("Regular")
            .font(.headline)
          AppCheckbox("Default on", isOn: .constant(true))
          AppCheckbox("Default off", isOn: .constant(false))
        }

        VStack(alignment: .leading) {
          Text("Small")
            .font(.headline)
          AppCheckbox("Default on", style: .small, isOn: .constant(true))
            .font(.caption)
          AppCheckbox("Default off", style: .small, isOn: .constant(false))
            .font(.caption)
        }
      }
    }
    .padding()
  }
}
