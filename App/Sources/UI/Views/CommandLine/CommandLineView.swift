import Apps
import Bonzai
import SwiftUI

extension AnyTransition {
  static var commandLineTransition: AnyTransition {
    .asymmetric(
      insertion:
          .scale(scale: 0.1, anchor: .topLeading)
          .combined(with: .opacity)
      ,
      removal:
          .scale(scale: 0.1, anchor: .topLeading)
          .combined(with: .opacity)
    )
  }
}


struct CommandLineViewModel: Equatable {
  var kind: Kind?
  var results: [Result]

  enum Kind: Equatable {
    case keyboard
    case app
    case url
    case fallback
  }

  enum Result: Hashable, Equatable, Identifiable {
    var id: String {
      switch self {
      case .app(let app): app.id
      case .url(let url): url.absoluteString
      case .search(let search): search.id
      }
    }

    case app(Application)
    case url(URL)
    case search(Search)

    struct Search: Hashable, Equatable, Identifiable {
      let id: String
      let name: String
      let text: String
      let prefix: String
      let searchString: String
    }
  }
}

struct CommandLineView: View {
  static let minHeight: CGFloat = 64
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

      if !coordinator.data.results.isEmpty {
        ZenDivider()
          .padding(.bottom, 8)

        CommandLineResultListView(data: coordinator.data,
                                  optionDown: $coordinator.optionDown,
                                  onTap: { coordinator.run() },
                                  selection: $coordinator.selection)
        .padding(.horizontal, 8)
      }
    }
    .background(
      .thinMaterial,
      in: RoundedRectangle(cornerRadius: 8, style: .continuous)
    )
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
        .textFieldStyle({ style in
          style.calm = true
          style.backgroundColor = Color.clear
          style.font = .largeTitle
          style.hoverEffect = false
        })
        .onSubmit(onSubmit)
    }
    .padding(2)
  }
}

private struct CommandLineResultListView: View {
  @Binding private var optionDown: Bool
  @Binding private var selection: Int
  static let animation: Animation = .smooth(duration: 0.2)
  private var data: CommandLineViewModel
  private let onTap: () -> Void

  init(data: CommandLineViewModel, optionDown: Binding<Bool>, 
       onTap: @escaping () -> Void,
       selection: Binding<Int>) {
    _selection = selection
    _optionDown = optionDown
    self.onTap = onTap
    self.data = data
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.vertical) {
        LazyVStack(spacing: 4) {
          ForEach(Array(zip(data.results.indices, data.results)), id: \.1.id) { offset, result in
            Group {
              switch result {
              case .app(let app):
                CommandLineApplicationView(app: app, optionDown: $optionDown)
                  .id(app.id)
              case .url(let url):
                CommandLineURLView(url: url)
                  .id(url.absoluteString)
              case .search(let search):
                CommandLineSearchView(search: search)
                  .id(result.id)
              }
            }
            .onTapGesture {
              selection = offset
              onTap()
            }
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor)
                .shadow(radius: 4)
                .opacity(selection == offset ? 0.25 : 0)
            )
            .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
          }
          .padding(.bottom, 8)
        }
      }
      .onChange(of: selection, perform: { value in
        guard data.results.indices.contains(value) else { return }
        proxy.scrollTo(data.results[value].id, anchor: .center)
      })
    }
  }
}

private struct CommandLineApplicationView: View {
  let app: Application
  @Binding var optionDown: Bool
  var body: some View {
    HStack(spacing: 10) {
      IconView(icon: .init(app), size: .init(width: 32, height: 32))
      VStack(alignment: .leading, spacing: 0) {
        Text(app.displayName)
          .frame(maxWidth: .infinity, alignment: .leading)
          .bold()
        Text(app.path)
          .font(.caption2)
          .lineLimit(1)
          .opacity(optionDown ? 0.6 : 0)
          .frame(maxHeight: optionDown ? nil : 0)
      }
    }
    .padding(4)
    .animation(.smooth(duration: 0.2), value: optionDown)
  }
}

private struct CommandLineURLView: View {
  let url: URL
  var body: some View {
    HStack(spacing: 10) {
      IconView(icon: .init(.safari()), size: .init(width: 32, height: 32))
      Text(url.absoluteString)
        .bold()
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
    }
    .padding(4)
  }
}

private struct CommandLineSearchView: View {
  let search: CommandLineViewModel.Result.Search
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 16, height: 16)
        .padding(.leading, 4)
      Text(search.text)
        .bold()
        .lineLimit(1)
        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
    }
    .padding(4)
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
        IconView(icon: .init(.safari()), size: .init(width: 32, height: 32))
      case .fallback:
        EmptyView()
      case .none:
        EmptyView()
      }
    }
    .frame(width: 32, height: 32)
    .background(
      Color.black.opacity(0.3).cornerRadius(8, antialiased: false)
    )
  }
}


#Preview {
  CommandLineView(coordinator: .shared)
}
