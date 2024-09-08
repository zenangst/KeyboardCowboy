import SwiftUI

enum BuiltinIconBuilder {
  @ViewBuilder @MainActor
  static func icon(_ kind: BuiltInCommand.Kind, size: CGFloat) -> some View {
    switch kind {
    case .macro(let action):
      switch action.kind {
      case .record: MacroIconView(.record, size: size)
      case .remove: MacroIconView(.remove, size: size)
      }
    case .userMode: UserModeIconView(size: size)
    case .commandLine: CommandLineIconView(size: size)
    case .repeatLastWorkflow: RepeatLastWorkflowIconView(size: size)
    }
  }
}
