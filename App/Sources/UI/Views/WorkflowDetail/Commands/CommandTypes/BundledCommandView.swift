import Bonzai
import SwiftUI

struct BundledCommandView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  private let model: CommandViewModel.Kind.BundledModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.BundledModel, iconSize: CGSize) {
    self.model = model
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(metaData, placeholder: model.placeholder) {
      switch model.kind {
      case .activatePreviousWorkspace: WorkspaceIcon(.activatePrevious, size: iconSize.width)
      case .appFocus: AppFocusIcon(size: iconSize.width)
      case .tidy: WindowTidyIcon(size: iconSize.width)
      case .workspace(let workspace): WorkspaceIcon(workspace.isDynamic ? .dynamic : .regular, size: iconSize.width)
      }
    } content: {
      switch model.kind {
      case .appFocus(let model):
        AppFocusCommandView(model: model) { tiling in
          performAppFocusUpdate(set: \.tiling, to: tiling)
        } onSelectedAppsChange: { application in
          performAppFocusUpdate(set: \.bundleIdentifer, to: application.bundleIdentifier)
        } onHideOtherAppsChange: { hideOtherApps in
          performAppFocusUpdate(set: \.hideOtherApps, to: hideOtherApps)
        } onCreateWindowChange: { createNewWindow in
          performAppFocusUpdate(set: \.createNewWindow, to: createNewWindow)
        }
      case .activatePreviousWorkspace:
        ActivatePreviousWorkspaceCommandView()
      case .tidy(let model):
        WindowTidyCommandView(model) { rules in
          let newRules = rules.map {
            WindowTidyCommand.Rule(bundleIdentifier: $0.application.bundleIdentifier, tiling: $0.tiling)
          }
          performTidyUpdate(set: \.rules, to: newRules)
        }
      case .workspace(let model):
        WorkspaceCommandView(
          model,
          onAppToggleModifiers:  { performWorkspaceUpdate(set: \.appToggleModifiers, to: $0) },
          onDefaultForDynamicWorkspace: { performWorkspaceUpdate(set: \.defaultForDynamicWorkspace, to: $0) },
          onHideOtherAppsChange: { performWorkspaceUpdate(set: \.hideOtherApps, to: $0) },
          onSelectedAppsChange:  { performWorkspaceUpdate(set: \.applications, to: $0.map { .init(bundleIdentifier: $0.bundleIdentifier, options: $0.options) } ) },
          onTilingChange:        { performWorkspaceUpdate(set: \.tiling, to: $0) },
        )
        .id(metaData.id)
      }
    }
  }

  private func performAppFocusUpdate<Value>(set keyPath: WritableKeyPath<AppFocusCommand, Value>, to value: Value) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.execution = .serial

      guard let index = workflow.commands.firstIndex(where: { $0.meta.id == metaData.id }),
            case .bundled(let bundledCommand) = workflow.commands[index],
            case .appFocus(var appFocusCommand) = bundledCommand.kind else { return }
      appFocusCommand[keyPath: keyPath] = value
      workflow.commands[index] = .bundled(BundledCommand(.appFocus(command: appFocusCommand), meta:  workflow.commands[index].meta))
    }
  }

  private func performWorkspaceUpdate<Value>(set keyPath: WritableKeyPath<WorkspaceCommand, Value>, to value: Value) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.execution = .serial
      guard let index = workflow.commands.firstIndex(where: { $0.meta.id == metaData.id }),
            case .bundled(let bundledCommand) = workflow.commands[index],
            case .workspace(var workspaceCommand) = bundledCommand.kind else { return }
      workspaceCommand[keyPath: keyPath] = value
      workflow.commands[index] = .bundled(BundledCommand(.workspace(command: workspaceCommand), meta: workflow.commands[index].meta))
    }
  }

  private func performTidyUpdate<Value>(set keyPath: WritableKeyPath<WindowTidyCommand, Value>, to value: Value) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.execution = .serial
      guard let index = workflow.commands.firstIndex(where: { $0.meta.id == metaData.id }),
            case .bundled(let bundledCommand) = workflow.commands[index],
            case .tidy(var tidyCommand) = bundledCommand.kind else { return }
      tidyCommand[keyPath: keyPath] = value
      workflow.commands[index] = .bundled(BundledCommand(.tidy(command: tidyCommand), meta: workflow.commands[index].meta))
    }
  }

}
