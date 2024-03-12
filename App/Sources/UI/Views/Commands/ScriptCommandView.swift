import Bonzai
import Inject
import SwiftUI

struct ScriptCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case updateName(newName: String)
    case updateSource(CommandViewModel.Kind.ScriptModel)
    case open(path: String)
    case reveal(path: String)
    case edit
    case commandAction(CommandContainerAction)
  }
  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.ScriptModel
  private let iconSize: CGSize
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.ScriptModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { _ in ScriptIconView(size: iconSize.width) },
      content: { _ in ScriptCommandContentView(model, onAction: onAction) },
      subContent: { _ in ScriptCommandSubContentView(model: model, onAction: onAction) },
      onAction: { onAction(.commandAction($0)) })
  }
}

private struct ScriptCommandContentView: View {
  @EnvironmentObject var openPanel: OpenPanelController
  @State private var text: String
  private let model: CommandViewModel.Kind.ScriptModel
  private let onAction: (ScriptCommandView.Action) -> Void

  init(_ model: CommandViewModel.Kind.ScriptModel,
       onAction: @escaping (ScriptCommandView.Action) -> Void) {
    self.model = model
    self.onAction = onAction

    switch model.source {
    case .inline(let source):
      _text = .init(initialValue: source)
    case .path(let source):
      _text = .init(initialValue: source)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      switch model.source {
      case .inline:
        ZenTextEditor(color: ZenColorPublisher.shared.color,
                      text: $text,
                      placeholder: "Script goes here…",
                      font: Font.system(.body, design: .monospaced))
        .onChange(of: text, perform: { newValue in
          onAction(.updateSource(.init(id: model.id, source: .inline(newValue),
                                       scriptExtension: model.scriptExtension)))
        })
        .padding([.trailing, .bottom], 8)

        HStack(spacing: 4) {
          Text("Environment:")
          Group {
            Button(action: { text.append(" $DIRECTORY") },
                   label: { Text("$DIRECTORY") })
            .help("$DIRECTORY: The current directory")
            Button(action: { text.append(" $FILE") },
                   label: { Text("$FILE") })
            .help("$FILE: The current file")
            Button(action: { text.append(" $FILENAME") },
                   label: { Text("$FILENAME") })
            .help("$FILENAME: The current filename")
            Button(action: { text.append(" $EXTENSION") },
                   label: { Text("$EXTENSION") })
            .help("$EXTENSION: The current file extension")
          }
          .buttonStyle(.zen(ZenStyleConfiguration(color: .black)))
        }
        .allowsTightening(true)
        .lineLimit(1)
        .font(.caption2)
        .padding(.leading, 4)
      case .path:
        HStack {
          TextField("Path", text: $text)
            .textFieldStyle(
              .zen(
                .init(
                  backgroundColor: Color.clear,
                  font: .callout,
                  padding: .init(horizontal: .medium, vertical: .medium),
                  unfocusedOpacity: 0.0
                )
              )
            )
            .onChange(of: text) { newPath in
              self.text = newPath
              onAction(.updateSource(.init(id: model.id, source: .path(newPath), scriptExtension: model.scriptExtension)))
            }
          Button("Browse", action: {
            openPanel.perform(.selectFile(type: model.scriptExtension.rawValue, handler: { newPath in
              self.text = newPath
              onAction(.updateSource(.init(id: model.id, source: .path(newPath), scriptExtension: model.scriptExtension)))
            }))
          })
          .buttonStyle(.zen(ZenStyleConfiguration(color: .systemBlue, grayscaleEffect: .constant(true))))
          .font(.caption)
        }
      }
    }
    .roundedContainer(padding: 4, margin: 0)
  }
}

private struct ScriptCommandSubContentView: View {
  private let model: CommandViewModel.Kind.ScriptModel
  private let onAction: (ScriptCommandView.Action) -> Void

  init(model: CommandViewModel.Kind.ScriptModel, onAction: @escaping (ScriptCommandView.Action) -> Void) {
    self.model = model
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      switch model.source {
      case .path(let source):
        Button("Open", action: { onAction(.open(path: source)) })
          .buttonStyle(.zen(ZenStyleConfiguration(color: .systemCyan, grayscaleEffect: .constant(true))))
        Button("Reveal", action: { onAction(.reveal(path: source)) })
          .buttonStyle(.zen(ZenStyleConfiguration(color: .systemBlue, grayscaleEffect: .constant(true))))
      case .inline:
        EmptyView()
      }
    }
    .font(.caption)
  }
}

struct ScriptCommandView_Previews: PreviewProvider {
  static let inlineCommand = DesignTime.scriptCommandInline
  static let pathCommand = DesignTime.scriptCommandWithPath

  static var previews: some View {
    Group {
      ScriptCommandView(inlineCommand.model.meta, model: inlineCommand.kind, iconSize: .init(width: 24, height: 24)) { _ in }
        .frame(maxHeight: 120)
        .previewDisplayName("Inline")
      ScriptCommandView(pathCommand.model.meta, model: pathCommand.kind, iconSize: .init(width: 24, height: 24)) { _ in }
        .frame(maxHeight: 120)
        .previewDisplayName("Path")
    }
    .designTime()
  }
}
