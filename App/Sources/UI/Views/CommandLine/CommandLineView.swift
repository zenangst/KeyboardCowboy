import Apps
import Bonzai
import SwiftUI

struct CommandLineViewModel: Equatable {
  var kind: Kind?
  var results: [Result]

  enum Kind: Equatable {
    case keyboard
    case app
    case url
  }

  enum Result: Hashable, Equatable, Identifiable {
    var id: String {
      switch self {
      case .app(let app): app.id
      case .url(let url): url.absoluteString
      }
    }

    case app(Application)
    case url(URL)
  }
}

struct CommandLineView: View {
  @StateObject var coordinator: CommandLineCoordinator

  init(coordinator: CommandLineCoordinator) {
    _coordinator = .init(wrappedValue: coordinator)
  }

  var body: some View {
    VStack(spacing: 0) {
      CommandLineInputView(
        data: coordinator.data,
        input: $coordinator.input,
        onSubmit: { coordinator.run() })
      .padding(.horizontal, 8)
      ZenDivider()
        .padding(.bottom, 4)
      CommandLineResultListView(data: coordinator.data, selection: $coordinator.selection)
        .padding(.horizontal, 8)
    }
    .background(
      LinearGradient(stops: [
        .init(color: Color(nsColor: .windowBackgroundColor), location: 0),
        .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.5, of: .black)!), location: 1)
      ], startPoint: .top, endPoint: .bottom)
    )
    .mask {
      RoundedRectangle(cornerRadius: 8)
    }
    .frame(minWidth: 400)
  }
}

private struct CommandLineInputView: View {
  @Binding private var input: String
  private var data: CommandLineViewModel
  private let onSubmit: () -> Void

  init(data: CommandLineViewModel, input: Binding<String>, onSubmit: @escaping () -> Void) {
  _input = input
  self.data = data
  self.onSubmit = onSubmit
}

  var body: some View {
    HStack(spacing: 4) {
      CommandLineImageView(data: data)
      TextField("Command Line…", text: $input)
        .textFieldStyle(
          .zen(.init(
            calm: true,
            color: .custom(.clear),
            backgroundColor: Color.clear,
            font: .largeTitle,
            hoverEffect: .constant(false))
          )
        )
        .onSubmit(onSubmit)
    }
    .padding(2)
  }
}

private struct CommandLineResultListView: View {
  @Binding private var selection: Int
  private var data: CommandLineViewModel

  init(data: CommandLineViewModel, selection: Binding<Int>) {
    _selection = selection
    self.data = data
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.vertical) {
        LazyVStack(spacing: 4) {
          ForEach(Array(zip(data.results.indices, data.results)), id: \.1) { offset, result in
            Group {
              switch result {
              case .app(let app):
                CommandLineApplicationView(app: app)
              case .url(let url):
                CommandLineURLView(url: url)
              }
            }
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor)
                .opacity(selection == offset ? 0.25 : 0)
            )
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
          }
        }
      }
      .onChange(of: selection, perform: { value in
        proxy.scrollTo(data.results[selection])
      })
    }
  }
}

private struct CommandLineApplicationView: View {
  let app: Application
  var body: some View {
    HStack(spacing: 4) {
      IconView(icon: .init(app), size: .init(width: 32, height: 32))
      VStack(alignment: .leading, spacing: 0) {
        Text(app.displayName)
          .frame(maxWidth: .infinity, alignment: .leading)
          .bold()
        Text(app.path)
          .font(.caption2)
          .opacity(0.6)
      }
    }
    .padding(4)
  }
}

private struct CommandLineURLView: View {
  let url: URL
  var body: some View {
    Text(url.absoluteString)
      .frame(maxWidth: .infinity, alignment: .leading)
      .bold()
  }
}

private struct CommandLineImageView: View {
  let data: CommandLineViewModel

  var body: some View {
    ZStack {
      Image(systemName: "app.dashed")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 24, height: 24)
        .foregroundColor(.white)
        .compositingGroup()
        .opacity(0.5)

      switch data.kind {
      case .app:
        GenericAppIconView(size: 24)
      case .keyboard:
        KeyboardIconView(">_", size: 24)
      case .url:
        IconView(icon: .init(.safari()), size: .init(width: 24, height: 24))
      case .none:
        EmptyView()
      }
    }
    .animation(.smooth(duration: 0.2), value: data.kind)
    .frame(width: 32, height: 32)
    .background(
      Color.black.opacity(0.3).cornerRadius(8, antialiased: false)
    )
  }
}

#Preview {
  CommandLineView(coordinator: .shared)
}
