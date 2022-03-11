import Apps
import SwiftUI

struct WorkflowGroupView: View, Equatable {
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    HStack {
      icon(24)
        .frame(width: 24, height: 24)
        .cornerRadius(24, antialiased: true)
      Text(group.name)
      Spacer()
    }.badge(group.workflows.count)
  }

  @ViewBuilder
  func icon(_ size: CGFloat) -> some View {
    if let rule = group.rule,
       let bundleIdentifier = rule.bundleIdentifiers.first,
       let application = applicationStore.dictionary[bundleIdentifier] {
      IconView(path: application.path)
        .frame(width: size + 6, height: size + 6)
    } else {
      WorkflowGroupIconView(group: $group, size: size)
        .frame(width: size, height: size)
    }
  }

  static func == (lhs: WorkflowGroupView, rhs: WorkflowGroupView) -> Bool {
    lhs.group.name == rhs.group.name &&
    lhs.group.color == rhs.group.color &&
    lhs.group.rule == rhs.group.rule &&
    lhs.group.symbol == rhs.group.symbol &&
    lhs.group.workflows.count == rhs.group.workflows.count
  }
}

struct WorkflowGroupView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowGroupView(applicationStore: ApplicationStore(),
                      group: .constant(WorkflowGroup.designTime()))
  }
}
