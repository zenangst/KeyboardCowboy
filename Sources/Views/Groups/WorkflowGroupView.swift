import Apps
import SwiftUI

struct WorkflowGroupView: View, Equatable {
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    HStack {
      icon
        .frame(width: 24, height: 24)
      Text(group.name)
      Spacer()
      Text("\(group.workflows.count)")
        .foregroundColor(.secondary)
        .font(.callout)
    }
  }

  @ViewBuilder
  var icon: some View {
    if let rule = group.rule,
       let bundleIdentifier = rule.bundleIdentifiers.first,
       let application = applicationStore.dictionary[bundleIdentifier] {
      IconView(path: application.path)
        .frame(width: 30, height: 30)
        .mask(Circle().frame(width: 24, height: 24))
    } else {
      WorkflowGroupIconView(group: $group, size: 24)
    }
  }

  static func == (lhs: WorkflowGroupView, rhs: WorkflowGroupView) -> Bool {
    lhs.group.name == rhs.group.name &&
    lhs.group.color == rhs.group.color &&
    lhs.group.rule == rhs.group.rule &&
    lhs.group.workflows.count == rhs.group.workflows.count
  }
}

struct WorkflowGroupView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowGroupView(applicationStore: ApplicationStore(),
                      group: .constant(WorkflowGroup.designTime()))
  }
}
