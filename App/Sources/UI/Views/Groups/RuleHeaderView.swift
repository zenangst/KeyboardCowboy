import Bonzai
import SwiftUI

struct RuleHeaderView: View {
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        GenericAppIconView(size: 24)
        ZenLabel("Rules")
      }
      Menu("Application") {
        ForEach(applicationStore.applications.lazy.filter({
          if let rule = group.rule {
            return !rule.bundleIdentifiers.contains($0.bundleIdentifier)
          } else {
            return true
          }
        }), id: \.path) { application in
          Button {
            if group.rule == .none {
              group.rule = .init()
            }
            group.rule?.bundleIdentifiers.append(application.bundleIdentifier)
          } label: {
            if application.metadata.isSafariWebApp {
              Text("\(application.displayName) (Safari Web App)")
            } else {
              Text(application.displayName)
            }
          }
        }
      }
      .menuStyle(.regular)
    }
  }
}
