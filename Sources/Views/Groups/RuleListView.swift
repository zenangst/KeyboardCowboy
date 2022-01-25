import Apps
import SwiftUI

struct RuleListView: View {
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup
  @State var selection: String = ""

  var body: some View {
    if let rule = group.rule {
      VStack(alignment: .leading) {
        Label("Rules", image: "")
          .labelStyle(HeaderLabelStyle())
        HStack {
          Picker("Application",
                 selection: $selection,
                 content: {
            ForEach(applicationStore.applications.filter({
              if let rule = group.rule {
                return !rule.bundleIdentifiers.contains($0.bundleIdentifier)
              } else {
                return true
              }
            }), id: \.bundleIdentifier) { application in
              Text(application.displayName)
                .id(application.bundleIdentifier)
            }
          })
          Spacer()
          Button(action: {
            guard !selection.isEmpty else { return }
            group.rule?.bundleIdentifiers.append(selection)
          }, label: { Text("Add") })
        }
        ForEach(rule.bundleIdentifiers, id: \.self) { bundleIdentifier in
          HStack {
            if let application = applicationStore.dictionary[bundleIdentifier] {
              IconView(path: application.path)
                .frame(width: 24, height: 24)
              Text(application.displayName)
            } else {
              Text(bundleIdentifier)
            }
            Spacer()
            Button(action: {
              group.rule?.bundleIdentifiers.removeAll(where: { $0 == bundleIdentifier })
            }, label: {
             Image(systemName: "trash")
            })
          }
        }
      }
    } else {
      Text("No rules applied.")
    }
  }
}

struct RuleListView_Previews: PreviewProvider {
  static let group = WorkflowGroup.designTime()
  static var previews: some View {
    RuleListView(applicationStore: ApplicationStore(),
                 group: .constant(group))
  }
}
