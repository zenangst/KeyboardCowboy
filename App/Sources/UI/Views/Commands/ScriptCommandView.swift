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
  @Binding private var model: CommandViewModel.Kind.ScriptModel
  private let iconSize: CGSize
  private let onAction: (Action) -> Void
  private let onSubmit: () -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: Binding<CommandViewModel.Kind.ScriptModel>,
       iconSize: CGSize,
       onSubmit: @escaping () -> Void,
       onAction: @escaping (Action) -> Void) {
    _model = model
    self.metaData = metaData
    self.iconSize = iconSize
    self.onSubmit = onSubmit
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { _ in ScriptIconView(size: iconSize.width) },
      content: { _ in
        ScriptCommandContentView(model, meta: metaData, onSubmit: onSubmit, onAction: onAction)
          .roundedContainer(4, padding: 4, margin: 0)
      },
      subContent: { _ in
        ScriptCommandSubContentView(model: model, metaData: metaData, onAction: onAction)
      },
      onAction: { onAction(.commandAction($0)) })
  }
}

struct ScriptCommandContentView: View {
  @EnvironmentObject var openPanel: OpenPanelController
  private let text: String
  private let model: CommandViewModel.Kind.ScriptModel
  private let onAction: (ScriptCommandView.Action) -> Void
  private let onSubmit: () -> Void

  init(_ model: CommandViewModel.Kind.ScriptModel,
       meta: CommandViewModel.MetaData,
       onSubmit: @escaping () -> Void,
       onAction: @escaping (ScriptCommandView.Action) -> Void) {
    self.model = model
    self.onAction = onAction
    self.onSubmit = onSubmit
    self.text = switch model.source {
    case .inline(let source): source
    case .path(let source): source
    }
  }

  var body: some View {
    ZStack {
      ScriptCommandInlineView(text: text,
                              variableName: model.variableName,
                              execution: model.execution,
                              onVariableNameChange: { variableName in
        onAction(.updateSource(.init(id: model.id, source: model.source,
                                     scriptExtension: model.scriptExtension,
                                     variableName: variableName,
                                     execution: model.execution)))
      }, onScriptChange: { newValue in
        onAction(.updateSource(.init(id: model.id, source: .inline(newValue),
                                     scriptExtension: model.scriptExtension,
                                     variableName: model.variableName,
                                     execution: model.execution)))
      }, onSubmit: onSubmit)
      .opacity(model.source.isInline ? 1 : 0)
      .frame(height: model.source.isInline ? nil : 0)

      ScriptCommandPathView(
        text, variableName: model.variableName,
        execution: model.execution,
        onVariableNameChange: { variableName in
          onAction(.updateSource(.init(id: model.id, source: model.source,
                                       scriptExtension: model.scriptExtension,
                                       variableName: variableName,
                                       execution: model.execution)))
        },
        onBrowse: {
          openPanel.perform(.selectFile(type: model.scriptExtension.rawValue, handler: { newPath in
            onAction(.updateSource(.init(id: model.id, source: .path(newPath),
                                         scriptExtension: model.scriptExtension,
                                         variableName: model.variableName,
                                         execution: model.execution)))
          }))
        }, onUpdate: { newPath in
          onAction(.updateSource(.init(id: model.id, source: .path(newPath),
                                       scriptExtension: model.scriptExtension,
                                       variableName: model.variableName,
                                       execution: model.execution)))
        })
      .opacity(model.source.isInline ? 0 : 1)
      .frame(height: model.source.isInline ? 0 : nil)
    }
  }
}

private struct ScriptCommandInlineView: View {
  @State private var text: String
  @State private var variableName: String
  private let execution: Workflow.Execution
  private let onVariableNameChange: (String) -> Void
  private let onScriptChange: (String) -> Void
  private let onSubmit: () -> Void

  init(text: String,
       variableName: String,
       execution: Workflow.Execution,
       onVariableNameChange: @escaping (String) -> Void,
       onScriptChange: @escaping (String) -> Void,
       onSubmit: @escaping () -> Void) {
    self.text = text
    self.variableName = variableName
    self.execution = execution
    self.onVariableNameChange = onVariableNameChange
    self.onScriptChange = onScriptChange
    self.onSubmit = onSubmit
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      ZenTextEditor(color: ZenColorPublisher.shared.color,
                    text: $text,
                    placeholder: "Script goes here…",
                    font: Font.system(.body, design: .monospaced), onCommandReturnKey: onSubmit)
      .onChange(of: text, perform: onScriptChange)

      ZenDivider()
      HStack(spacing: 2) {
        EnvironmentIconView(size: 24)
        ZenDivider(.vertical)
          .fixedSize()
        ScrollView(.horizontal) {
          HStack {
            ForEach(UserSpace.EnvironmentKey.allCases, id: \.rawValue) { env in
              Button(action: { text.append(env.asTextVariable) },
                     label: { Text(env.asTextVariable) })
              .help("\(env.asTextVariable): \(env.help)")
            }
            .padding(.vertical, 4)
          }
          .padding(.horizontal, 4)
        }
        .roundedContainer(4, padding: 0, margin: 0)
        .padding(.horizontal, 4)
      }
      .buttonStyle(.zen(ZenStyleConfiguration(color: .systemGreen)))
      .allowsTightening(true)
      .lineLimit(1)
      .font(.caption2)
      .padding(.leading, 4)

      ScriptCommandAssignToVariableView(variableName: variableName,
                                        execution: execution,
                                        onVariableNameChange: onVariableNameChange)
    }
  }
}

private struct ScriptCommandPathView: View {
  @State private var text: String
  @State private var variableName: String
  private let execution: Workflow.Execution
  private let onVariableNameChange: (String) -> Void
  private let onBrowse: () -> Void
  private let onUpdate: (String) -> Void

  init(_ text: String,
       variableName: String,
       execution: Workflow.Execution,
       onVariableNameChange: @escaping (String) -> Void,
       onBrowse: @escaping () -> Void,
       onUpdate: @escaping (String) -> Void) {
    _text = .init(initialValue: text)
    self.execution = execution
    self.onBrowse = onBrowse
    self.onUpdate = onUpdate
    self.onVariableNameChange = onVariableNameChange
    self.variableName = variableName
  }

  var body: some View {
    VStack(spacing: 0) {
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
            onUpdate(newPath)
          }
        Button("Browse", action: onBrowse)
          .buttonStyle(.zen(ZenStyleConfiguration(color: .systemBlue, grayscaleEffect: .constant(true))))
          .font(.caption)
      }
      ScriptCommandAssignToVariableView(
        variableName: variableName,
        execution: execution,
        onVariableNameChange: onVariableNameChange
      )
      .opacity(execution == .serial ? 1 : 0)
      .frame(maxHeight: execution == .serial ? nil : 0)
    }
  }
}

private struct ScriptCommandSubContentView: View {
  private let model: CommandViewModel.Kind.ScriptModel
  private let metaData: CommandViewModel.MetaData
  private let onAction: (ScriptCommandView.Action) -> Void

  init(model: CommandViewModel.Kind.ScriptModel,
       metaData: CommandViewModel.MetaData,
       onAction: @escaping (ScriptCommandView.Action) -> Void) {
    self.model = model
    self.metaData = metaData
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      Menu {
        Button(action: { onAction(.commandAction(.toggleNotify(nil))) }, label: { Text("None") })
        ForEach(Command.Notification.allCases) { notification in
          Button(action: { onAction(.commandAction(.toggleNotify(notification))) },
                 label: { Text(notification.displayValue) })
        }
      } label: {
        switch metaData.notification {
        case .bezel:
          Text("Bezel")
            .font(.caption)
        case .commandPanel:
          Text("Command Panel")
            .font(.caption)
        case .none:
          Text("None")
            .font(.caption)
        }
      }
      .menuStyle(.zen(.init(color: .systemGray, padding: .large)))
      .fixedSize()
      switch model.source {
      case .path(let source):
        Spacer()
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

private struct ScriptCommandAssignToVariableView: View {
  @State var variableName: String
  private let execution: Workflow.Execution
  private let onVariableNameChange: (String) -> Void

  init(variableName: String, execution: Workflow.Execution, onVariableNameChange: @escaping (String) -> Void) {
    self.variableName = variableName
    self.execution = execution
    self.onVariableNameChange = onVariableNameChange
  }

  var body: some View {
    Group {
      ZenDivider()
      HStack(spacing: 2) {
        MagicVarsIconView(size: 24)
        ZenDivider(.vertical)
          .fixedSize()
        TextField("Assign output to variable", text: $variableName)
          .textFieldStyle(.zen(.init(font: .caption)))
          .onChange(of: variableName) { newValue in
            onVariableNameChange(newValue)
          }
          .roundedContainer(4, padding: 0, margin: 0)
          .padding(.horizontal, 4)
      }
      .font(.caption2)
      .padding([.leading, .bottom], 4)
    }
    .opacity(execution == .serial ? 1 : 0)
    .frame(maxHeight: execution == .serial ? nil : 0)
  }
}

fileprivate extension ScriptCommand.Source {
  var isInline: Bool {
    switch self {
    case .path: false
    case .inline: true
    }
  }
}

struct ScriptCommandView_Previews: PreviewProvider {
  static let inlineCommand = DesignTime.scriptCommandInline
  static let pathCommand = DesignTime.scriptCommandWithPath

  static var previews: some View {
    Group {
      ScriptCommandView(inlineCommand.model.meta,
                        model: .constant(inlineCommand.kind),
                        iconSize: .init(width: 24, height: 24),
                        onSubmit: { },
                        onAction: { _ in })
        .previewDisplayName("Inline")
      ScriptCommandView(pathCommand.model.meta, model: .constant(pathCommand.kind), iconSize: .init(width: 24, height: 24),
                        onSubmit: {}, onAction: { _ in })
        .previewDisplayName("Path")
    }
    .designTime()
  }
}
