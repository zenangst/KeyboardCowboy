import SwiftUI

enum SystemIconBuilder {
  @ViewBuilder @MainActor
  static func icon(_ kind: SystemCommand.Kind?, size: CGFloat) -> some View {
    switch kind {
    case .activateLastApplication: ActivateLastApplicationIconView(size: size)
    case .applicationWindows: MissionControlIconView(size: size)
    case .minimizeAllOpenWindows: MinimizeAllIconView(size: size)
    case .hideAllApps: HideAllIconView(size: size)
    case .fillAllOpenWindows: EmptyView() // TODO: Fix this!
    case .missionControl: MissionControlIconView(size: size)
    case .showDesktop: DockIconView(size: size)
    case .none: EmptyView()
    }
  }
}
