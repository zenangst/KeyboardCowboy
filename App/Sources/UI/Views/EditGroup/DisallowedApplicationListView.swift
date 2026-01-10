import Apps
import Bonzai
import HotSwiftUI
import SwiftUI

struct DisallowedApplicationsListView: View {
  @ObserveInjection var inject
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    VStack(alignment: .leading) {
      if let rule = group.rule, !rule.disallowedBundleIdentifiers.isEmpty {
        ForEach(rule.disallowedBundleIdentifiers, id: \.self) { bundleIdentifier in
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
              group.rule?.disallowedBundleIdentifiers.removeAll(where: { $0 == bundleIdentifier })
              if group.rule?.allowedBundleIdentifiers.isEmpty == true,
                 group.rule?.disallowedBundleIdentifiers.isEmpty == true {
                group.rule = nil
              }
            }, label: {
              Image(systemName: "trash")
            })
            .buttonStyle(.destructive)
          }
          ZenDivider()
        }
      } else {
        explaination
      }
    }
    .style(.item)
    .style(.derived)
    .enableInjection()
  }

  var explaination: some View {
    VStack {
      Group {
        Text("Workflows in this Group are deactivated when the following applications are the frontmost app. ")
      }
      .foregroundStyle(.secondary)
      .font(.caption)
      .frame(maxWidth: .infinity)
    }
  }
}

struct DisallowedApplicationsListView_Previews: PreviewProvider {
  static let group = WorkflowGroup.designTime()
  static var previews: some View {
    DisallowedApplicationsListView(applicationStore: ApplicationStore.shared,
                                   group: .constant(group))
      .padding()
  }
}
