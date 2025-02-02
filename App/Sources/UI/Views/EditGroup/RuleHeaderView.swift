import Bonzai
import Inject
import SwiftUI

struct RuleHeaderView: View {
  @ObserveInjection var inject
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 0) {
        GenericAppIconView(size: 16)
          .style(.derived)
        ZenLabel("Rules")
          .style(.derived)
      }
      .style(.derived)

      ZenDivider()

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
      .style(.derived)
      .style(.list)
    }
    .enableInjection()
  }
}
