import Apps
import SwiftUI
import Bonzai

struct RuleListView: View {
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    VStack(alignment: .leading) {
      if let rule = group.rule {
        ForEach(rule.bundleIdentifiers, id: \.self) { bundleIdentifier in
          Divider()
          HStack {
            Group {
              if let application = applicationStore.dictionary[bundleIdentifier] {
                IconView(icon: .init(bundleIdentifier: application.bundleIdentifier, path: application.path),
                         size: .init(width: 24, height: 24))
                Text(application.displayName)
              } else {
                Text(bundleIdentifier)
              }
            }
            .padding(.leading)
            Spacer()
            Button(action: {
              group.rule?.bundleIdentifiers.removeAll(where: { $0 == bundleIdentifier })
            }, label: {
              Image(systemName: "trash")
            })
            .buttonStyle(.calm(color: .systemRed, padding: .medium))
            .padding(.trailing)
          }
        }
      } else {
        Text("No rules applied.")
      }
    }
  }
}

struct RuleListView_Previews: PreviewProvider {
  static let group = WorkflowGroup.designTime()
  static var previews: some View {
    RuleListView(applicationStore: ApplicationStore.shared,
                 group: .constant(group))
    .padding()
  }
}
