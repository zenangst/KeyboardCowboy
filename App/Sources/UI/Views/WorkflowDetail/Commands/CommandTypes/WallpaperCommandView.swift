import Bonzai
import SwiftUI//

struct WallpaperCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding var model: CommandViewModel.Kind.WallpaperModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ model: Binding<CommandViewModel.Kind.WallpaperModel>, metaData: CommandViewModel.MetaData, iconSize: CGSize) {
    _model = model
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: "",
      icon: { EmptyView() },
      content: { ContentView(model: $model) },
      subContent: { })
    .id(model.id)
    .enableInjection()
  }
}

private struct ContentView: View {
  @Binding var model: CommandViewModel.Kind.WallpaperModel

  var body: some View {
    VStack(spacing: 4) {
      Menu {
        Button(action: { model.source = .file(path: "") },
               label: {
          HStack {
            Image(systemName: "photo")
            Text("File")
          }
        })
        Button(action: { model.source = .folder(folder: .init(path: "", strategy: .random)) },
               label: {
          HStack {
            Image(systemName: "photo.stack.fill")
            Text("Folder")
          }
        })
      } label: {
        Text(model.source.displayValue)
        Image(systemName: model.source.symbolValue)
      }

      ZenDivider()

      Group {
        switch model.source {
        case .file(let path):
          FileView(model: $model, path: path)
        case .folder(let folder):
          FolderView(model: $model, path: folder.path)
        }
      }
    }
    .style(.derived)
  }
}

private struct FileView: View {
  @EnvironmentObject var openPanel: OpenPanelController
  @Binding var model: CommandViewModel.Kind.WallpaperModel
  @State var path: String

  var body: some View {
    HStack {
      TextField("", text: $path)
        .environment(\.textFieldBackgroundColor, .clear)
        .environment(\.textFieldFont, .callout)
        .environment(\.textFieldPadding, .mini)
        .environment(\.textFieldUnfocusedOpacity, 0.0)
        .onChange(of: path, perform: { newValue in
          model.source = .file(path: newValue)
        })
        .frame(maxWidth: .infinity)

      Button {
        openPanel.perform(.selectFile(types: ["png", "jpg", "jpeg", "hiec"], handler: { newPath in
          self.path = newPath
        }))
      } label: {
        Text("Browse")
      }
      .environment(\.buttonCalm, false)
      .environment(\.buttonGrayscaleEffect, false)
      .environment(\.buttonFocusEffect, false)
      .environment(\.buttonUnfocusedOpacity, 0.4)
      .environment(\.buttonPadding, .medium)
    }

    VStack(spacing: 0) {
      ScrollView {
        ScreensView(model: $model)
          .frame(maxWidth: .infinity)
      }
      .frame(maxHeight: min(32 * max(CGFloat(model.screens.count), 1), 200))

      ZenDivider()

      Button(action: {
        model.screens.append(.init(id: UUID().uuidString, match: .screenName("")))
      }) {
        Text("Add Screen")
      }
      .environment(\.buttonBackgroundColor, .systemGreen)
      .environment(\.buttonCalm, false)
      .environment(\.buttonHoverEffect, true)
      .environment(\.buttonGrayscaleEffect, false)
      .environment(\.buttonUnfocusedOpacity, 0.4)
      .environment(\.buttonFont, .body)
      .padding(.top, 8)
    }
    .style(.list)
    .roundedSubStyle()
  }
}

private struct FolderView: View {
  @EnvironmentObject var openPanel: OpenPanelController
  @Binding var model: CommandViewModel.Kind.WallpaperModel
  @State var path: String

  var body: some View {
    HStack {
      TextField("", text: $path)
        .environment(\.textFieldBackgroundColor, .clear)
        .environment(\.textFieldFont, .callout)
        .environment(\.textFieldPadding, .mini)
        .environment(\.textFieldUnfocusedOpacity, 0.0)
        .onChange(of: path, perform: { newValue in
          model.source = .folder(folder: .init(path: newValue, strategy: .random))
        })
        .frame(maxWidth: .infinity)

      Button {
        openPanel.perform(.selectFolder(allowMultipleSelections: false, handler: { newPath in
          self.path = newPath
        }))
      } label: {
        Text("Browse")
      }
      .environment(\.buttonCalm, false)
      .environment(\.buttonGrayscaleEffect, false)
      .environment(\.buttonFocusEffect, false)
      .environment(\.buttonUnfocusedOpacity, 0.4)
      .environment(\.buttonPadding, .medium)
    }
  }
}

private struct ScreensView: View {
  @Binding var model: CommandViewModel.Kind.WallpaperModel

  init(model: Binding<CommandViewModel.Kind.WallpaperModel>) {
    _model = model
  }

  var body: some View {
    VStack {
      ForEach($model.screens) { screen in
        ScreenView(screen: screen, onRemove: { screen in
          model.screens.removeAll(where: { $0.id == screen.id })
        })
      }
    }
  }
}

private struct ScreenView: View {
  @Binding var screen: WallpaperCommand.Screen
  let onRemove: (WallpaperCommand.Screen) -> Void
  @State var matchingString: String

  init(screen: Binding<WallpaperCommand.Screen>, onRemove: @escaping (WallpaperCommand.Screen) -> Void) {
    _screen = screen
    self.onRemove = onRemove
    switch screen.wrappedValue.match {
    case .screenName(let name):
      _matchingString = .init(initialValue: name)
    default:
      _matchingString = .init(initialValue: "")
    }
  }

  var body: some View {
    HStack {
      Menu {
        Button(action: { screen.match = .active }, label: { Text(WallpaperCommand.Match.active.displayValue) })
        Button(action: { screen.match = .main }, label: { Text(WallpaperCommand.Match.main.displayValue) })
        Button(action: { screen.match = .screenName("") }, label: { Text(WallpaperCommand.Match.screenName("match").displayValue) })
      } label: {
        Text(screen.match.displayValue)
      }

      switch screen.match {
      case .active: EmptyView()
      case .main: EmptyView()
      case .screenName:
        TextField("", text: $matchingString)
          .environment(\.textFieldBackgroundColor, .clear)
          .environment(\.textFieldFont, .callout)
          .environment(\.textFieldPadding, .mini)
          .environment(\.textFieldUnfocusedOpacity, 0.0)
          .onChange(of: matchingString, perform: { newValue in
            screen.match = .screenName(newValue)
          })
          .frame(maxWidth: .infinity)
      }

      Button(action: {
        onRemove(screen)
      }, label: {
        Image(systemName: "xmark")
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 6, height: 10)
      })
      .buttonStyle(.destructive)
    }
  }
}

#Preview("Folder") {
  WallpaperCommandView(
    .constant(
      .init(
        id: UUID().uuidString,
        source: .folder(folder: .init(path: "~", strategy: .random)),
        screens: [
          .init(id: UUID().uuidString, match: .screenName("Built-in"))
        ]
      )
    ),
    metaData: .init(name: "Wallpaper Command", namePlaceholder: ""),
    iconSize: .init(width: 24, height: 24)
  )
  .designTime()
}

#Preview("File") {
  WallpaperCommandView(
    .constant(
      .init(
        id: UUID().uuidString,
        source: .file(path: "File"),
        screens: [
          .init(id: UUID().uuidString, match: .screenName("Built-in"))
        ]
      )
    ),
    metaData: .init(name: "Wallpaper Command", namePlaceholder: ""),
    iconSize: .init(width: 24, height: 24)
  )
  .designTime()
}

