import Bonzai
import SwiftUI

struct BundledCommandView: View {
  enum Action {
    case editCommand(CommandViewModel.Kind.BundledModel.Kind)
    case commandAction(CommandContainerAction)
  }

  private let model: CommandViewModel.Kind.BundledModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.BundledModel,
       iconSize: CGSize, onAction: @escaping (Action) -> Void) {
    self.model = model
    self.metaData = metaData
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(metaData, placeholder: "") { _ in
      switch model.kind {
      case .workspace: WorkspaceIcon(size: iconSize.width)
      }
    } content: { _ in
      switch model.kind {
      case .workspace(let model):
        WorkspaceCommandView(model) { tiling in
          onAction(.editCommand(.workspace(.init(applications: model.applications,
                                                 tiling: tiling,
                                                 hideOtherApps: model.hideOtherApps))))
        } onSelectedAppsChange: { applications in
          onAction(.editCommand(.workspace(.init(applications: applications,
                                                 tiling: model.tiling,
                                                 hideOtherApps: model.hideOtherApps))))
        } onHideOtherAppsChange: { hideOtherApps in
          onAction(.editCommand(.workspace(.init(applications: model.applications,
                                                 tiling: model.tiling,
                                                 hideOtherApps: hideOtherApps))))
        }
        .id(metaData.id)
      }
    } onAction: { action in
      onAction(.commandAction(action))
    }
  }
}
