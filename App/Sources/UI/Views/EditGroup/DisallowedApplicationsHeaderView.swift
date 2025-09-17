import Bonzai
import Inject
import SwiftUI

struct DisallowedApplicationsHeaderView: View {
  @ObserveInjection var inject
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 0) {
        GenericAppIconView(primaryColor: .systemRed, size: 16)
          .style(.derived)
        ZenLabel("Disallowed Applications")
          .style(.derived)
      }
      .style(.derived)

      ZenDivider()

      Menu("Applications") {
        ForEach(applicationStore.applications.lazy.filter {
          if let rule = group.rule {
            return !rule.disallowedBundleIdentifiers.contains($0.bundleIdentifier)
          } else {
            return true
          }
        }, id: \.path) { application in
          Button {
            if group.rule == .none {
              group.rule = .init()
            }
            group.rule?.disallowedBundleIdentifiers.append(application.bundleIdentifier)
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
