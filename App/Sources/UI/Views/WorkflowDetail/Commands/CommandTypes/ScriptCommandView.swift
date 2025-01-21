import Bonzai
import Inject
import SwiftUI

struct ScriptCommandView: View {
  @ObserveInjection var inject
  private let metaData: CommandViewModel.MetaData
  @Binding private var model: CommandViewModel.Kind.ScriptModel
  private let iconSize: CGSize
  private let onSubmit: () -> Void

  init(_ metaData: CommandViewModel.MetaData, model: Binding<CommandViewModel.Kind.ScriptModel>,
       iconSize: CGSize, onSubmit: @escaping () -> Void) {
    _model = model
    self.metaData = metaData
    self.iconSize = iconSize
    self.onSubmit = onSubmit
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { _ in ScriptIconView(size: iconSize.width) },
      content: { _ in
        ScriptCommandContentView(metaData: metaData, model: model, onSubmit: onSubmit)
          .roundedContainer(4, padding: 4, margin: 0)
      },
      subContent: {
        ScriptCommandSubContentView(model: model, metaData: metaData)
      })
  }
}

struct ScriptCommandContentView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject var openPanel: OpenPanelController
  private let metaData: CommandViewModel.MetaData
  private let text: String
  private let model: CommandViewModel.Kind.ScriptModel
  private let onSubmit: () -> Void

  init(metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.ScriptModel, onSubmit: @escaping () -> Void) {
    self.metaData = metaData
    self.model = model
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
        performUpdate { $0.variableName = variableName }
      }, onScriptChange: { newValue in
        performUpdate { $0.source = .inline(newValue) }
      }, onSubmit: onSubmit)
      .opacity(model.source.isInline ? 1 : 0)
      .frame(height: model.source.isInline ? nil : 0)

      ScriptCommandPathView(
        text, variableName: model.variableName,
        execution: model.execution,
        onVariableNameChange: { variableName in
          performUpdate { $0.variableName = variableName }
        },
        onBrowse: {
          openPanel.perform(.selectFile(type: model.scriptExtension.rawValue, handler: { newPath in
            performUpdate { $0.source = .path(newPath) }
          }))
        }, onUpdate: { newPath in
          performUpdate { $0.source = .path(newPath) }
        })
      .opacity(model.source.isInline ? 0 : 1)
      .frame(height: model.source.isInline ? 0 : nil)
    }
  }

  private func performUpdate(_ update: (inout ScriptCommand) -> Void) {
    updater.modifyCommand(withID: metaData.id, using: transaction) { command in
      guard case .script(var scriptCommand) = command else { return }
      update(&scriptCommand)
      command = .script(scriptCommand)
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
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  private let model: CommandViewModel.Kind.ScriptModel
  private let metaData: CommandViewModel.MetaData

  init(model: CommandViewModel.Kind.ScriptModel, metaData: CommandViewModel.MetaData) {
    self.model = model
    self.metaData = metaData
  }

  var body: some View {
    HStack {
      Menu {
        Button(action: {
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            command.notification = .none
          }
        }, label: { Text("None") })
        ForEach(Command.Notification.allCases) { notification in
          Button(action: {
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              command.notification = notification
            }
          }, label: { Text(notification.displayValue) })
        }
      } label: {
        switch metaData.notification {
        case .bezel:        Text("Bezel").font(.caption)
        case .capsule:      Text("Capsule").font(.caption)
        case .commandPanel: Text("Command Panel").font(.caption)
        case .none:         Text("None").font(.caption)
        }
      }
      .menuStyle(.zen(.init(color: .systemGray, padding: .medium)))
      .fixedSize()

      switch model.source {
      case .path(let source):
        Spacer()
        Button("Open", action: {
          NSWorkspace.shared.open(URL(fileURLWithPath: source))
        })
          .buttonStyle(.zen(ZenStyleConfiguration(color: .systemCyan, grayscaleEffect: .constant(true))))
        Button("Reveal", action: {
          NSWorkspace.shared.reveal(source)
        })
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
          .textFieldStyle(.zen(.init(font: .caption, padding: ZenStyleConfiguration.Padding(horizontal: .extraLarge, vertical: .small))))
          .overlay(alignment: .leading) {
            Text("$")
              .padding(.leading, 4)
              .opacity(0.5)
          }
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
      ScriptCommandView(inlineCommand.model.meta, model: .constant(inlineCommand.kind),
                        iconSize: .init(width: 24, height: 24), onSubmit: { })
        .previewDisplayName("Inline")
      ScriptCommandView(pathCommand.model.meta, model: .constant(pathCommand.kind),
                        iconSize: .init(width: 24, height: 24), onSubmit: {})
        .previewDisplayName("Path")
    }
    .designTime()
  }
}
