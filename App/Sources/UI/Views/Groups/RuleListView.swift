import Apps
import SwiftUI

struct RuleListView: View {
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    VStack(alignment: .leading) {
      Label("Rules", image: "")
        .labelStyle(HeaderLabelStyle())
      HStack {
        Menu("Application") {
          ForEach(applicationStore.applications.filter({
            if let rule = group.rule {
              return !rule.bundleIdentifiers.contains($0.bundleIdentifier)
            } else {
              return true
            }
          }), id: \.bundleIdentifier) { application in
            Button {
              if group.rule == .none {
                group.rule = .init()
              }
              group.rule?.bundleIdentifiers.append(application.bundleIdentifier)
            } label: {
              Text(application.displayName)
            }
          }
        }
        .menuStyle(GradientMenuStyle(.init(nsColor: .systemGray, grayscaleEffect: false)))
      }
      if let rule = group.rule {
        ForEach(rule.bundleIdentifiers, id: \.self) { bundleIdentifier in
          Divider()
          HStack {
            if let application = applicationStore.dictionary[bundleIdentifier] {
              IconView(icon: .init(bundleIdentifier: application.bundleIdentifier, path: application.path),
                       size: .init(width: 24, height: 24))
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
      } else {
        Text("No rules applied.")
      }
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
