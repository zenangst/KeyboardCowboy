import Bonzai
import HotSwiftUI
import SwiftUI

struct AllowedApplicationsHeaderView: View {
  @ObserveInjection var inject
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 0) {
        GenericAppIconView(primaryColor: .systemGreen, size: 16)
          .style(.derived)
        ZenLabel("Allowed Applications")
          .style(.derived)
      }
      .style(.derived)

      ZenDivider()

      Menu(content: {
        ForEach(applicationStore.applications.lazy.filter {
          if let rule = group.rule {
            !rule.allowedBundleIdentifiers.contains($0.bundleIdentifier)
          } else {
            true
          }
        }, id: \.path) { application in
          Button {
            if group.rule == .none {
              group.rule = .init()
            }
            group.rule?.allowedBundleIdentifiers.append(application.bundleIdentifier)
          } label: {
            if application.metadata.isSafariWebApp {
              Text("\(application.displayName) (Safari Web App)")
            } else {
              Text(application.displayName)
            }
          }
        }
      }, label: {
        Text("Applications")
          .frame(maxWidth: .infinity)
      })
      .frame(maxWidth: .infinity)
      .style(.derived)
      .style(.list)
    }
    .enableInjection()
  }
}
