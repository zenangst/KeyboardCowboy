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
  @EnvironmentObject var selection: SelectionManager<CommandViewModel>
  @EnvironmentObject var openPanel: OpenPanelController
  @State private var text: String
  @State private var metaData: CommandViewModel.MetaData
  @State private var model: CommandViewModel.Kind.ScriptModel
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.ScriptModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)

    switch model.source {
    case .inline(let source):
      _text = .init(initialValue: source)
    case .path(let source):
      _text = .init(initialValue: source)
    }

    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData,
                         icon: {
      command in
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        IconView(
          icon: .init(
            bundleIdentifier: "/System/Applications/Utilities/Script Editor.app",
            path: "/System/Applications/Utilities/Script Editor.app"
          ),
          size: .init(width: 32, height: 32)
        )
      }
    },
                         content: { metaData in
      VStack {
        HStack(spacing: 8) {
          TextField("", text: $metaData.name)
            .textFieldStyle(.regular(Color(.windowBackgroundColor)))
            .onChange(of: metaData.wrappedValue.name, perform: {
              onAction(.updateName(newName: $0))
            })
          Spacer()
        }
        
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
            RoundedRectangle(cornerRadius: 6, style: .continuous)
              .fill(Color(nsColor: .systemYellow))
              .betaFeature("Script environment variables only work in application that have documents.") {
                Text("BETA")
                  .foregroundStyle(Color.black)
                  .font(.caption2)
                  .frame(maxWidth: .infinity)
              }
              .frame(width: 32)
            Spacer()
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
          .frame(alignment: .leading)
          .padding(.trailing)
        case .path:
          HStack {
            TextField("Path", text: $text)
              .textFieldStyle(FileSystemTextFieldStyle())
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
    },
                         subContent: { _ in
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
    },
                         onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct ScriptCommandView_Previews: PreviewProvider {
  static let inlineCommand = DesignTime.scriptCommandInline
  static let pathCommand = DesignTime.scriptCommandWithPath

  static var previews: some View {
    Group {
      ScriptCommandView(inlineCommand.model.meta, model: inlineCommand.kind) { _ in }
        .frame(maxHeight: 120)
        .previewDisplayName("Inline")
      ScriptCommandView(pathCommand.model.meta, model: pathCommand.kind) { _ in }
        .frame(maxHeight: 120)
        .previewDisplayName("Path")
    }
    .designTime()
  }
}
