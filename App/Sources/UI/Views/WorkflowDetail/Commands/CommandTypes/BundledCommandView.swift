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
    CommandContainerView(metaData, placeholder: "") { _ in
      switch model.kind {
      case .workspace: WorkspaceIcon(size: iconSize.width)
      case .appFocus: AppFocusIcon(size: iconSize.width)
      }
    } content: { _ in
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
      case .workspace(let model):
        WorkspaceCommandView(model) { tiling in
          performWorkspaceUpdate(set: \.tiling, to: tiling)
        } onSelectedAppsChange: { applications in
          performWorkspaceUpdate(set: \.bundleIdentifiers, to: applications.map(\.bundleIdentifier))
        } onHideOtherAppsChange: { hideOtherApps in
          performWorkspaceUpdate(set: \.hideOtherApps, to: hideOtherApps)
        }
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
      workflow.commands[index] = .bundled(BundledCommand(.appFocus(appFocusCommand), meta:  workflow.commands[index].meta))
    }
  }

  private func performWorkspaceUpdate<Value>(set keyPath: WritableKeyPath<WorkspaceCommand, Value>, to value: Value) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.execution = .serial
      guard let index = workflow.commands.firstIndex(where: { $0.meta.id == metaData.id }),
            case .bundled(let bundledCommand) = workflow.commands[index],
            case .workspace(var workspaceCommand) = bundledCommand.kind else { return }
      workspaceCommand[keyPath: keyPath] = value
      workflow.commands[index] = .bundled(BundledCommand(.workspace(workspaceCommand), meta: workflow.commands[index].meta))
    }
  }
}
