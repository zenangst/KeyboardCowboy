import Apps
import Inject
import SwiftUI
import Bonzai

struct RuleListView: View {
  @ObserveInjection var inject
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    VStack(alignment: .leading) {
      if let rule = group.rule {
        ForEach(rule.bundleIdentifiers, id: \.self) { bundleIdentifier in
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
            Spacer()
            Button(action: {
              group.rule?.bundleIdentifiers.removeAll(where: { $0 == bundleIdentifier })
              if group.rule?.bundleIdentifiers.isEmpty == true { group.rule = nil }
            }, label: {
              Image(systemName: "trash")
            })
            .buttonStyle(.destructive)
          }
          .style(.item)
          .style(.derived)
          ZenDivider()
        }
      } else {
        VStack {
          Text("No Rules applied.")
            .frame(maxWidth: .infinity)
        }
      }
    }
    .enableInjection()
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
