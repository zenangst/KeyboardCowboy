import SwiftUI

enum PermissionsItemStatus: String {
  case request = "Request"
  case approved = "Approved"
  case pending = "Pending"
  case unknown = "Unknown"
}

struct PermissionsSettings: View {
  @StateObject var accessibilityPermission = AccessibilityPermission.shared
  @StateObject var locationPermission = LocationPermission.shared

  var body: some View {
    VStack {
      Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 32) {
        GridRow {
          PermissionOverviewItem(
            status: .readonly(accessibilityPermission.viewModel),
            icon: "command.circle.fill",
            name: "Accessibility permissions",
            explanation: "Used to trigger workflows when you press a keyboard shortcut.",
            color: Color(.systemPurple)
          ) {
            AccessibilityPermission.shared.requestPermission()
          }
          .animation(.easeInOut, value: accessibilityPermission.viewModel)
        }
      }
    }
    .padding(24)
    .frame(minWidth: 480)
  }
}

fileprivate struct PermissionOverviewItem: View {
  @Namespace var namespace
  @Binding var status: PermissionsItemStatus

  let icon: String
  let name: String
  let explanation: String
  let color: Color
  let onAction: () -> Void

  var body: some View {
    Image(systemName: icon)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: 24, height: 24)
      .foregroundStyle(color)
      .background(Circle().fill(Color.white).padding(4))

    VStack(alignment: .leading) {
      Text(name)
        .font(.headline)
        .bold()
      Text(explanation)
        .font(.caption)
    }
    .frame(maxWidth: .infinity, alignment: .leading)

    HStack {
      switch status {
      case .approved:
        Image(systemName: "checkmark.circle.fill")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 20, height: 20)
          .foregroundStyle(Color(.systemGreen))
          .matchedGeometryEffect(id: "permission-overview-item", in: namespace)
      case .pending:
        ProgressView()
          .progressViewStyle(.circular)
          .matchedGeometryEffect(id: "permission-overview-item", in: namespace)
      case .request, .unknown:
        Button(action: onAction, label: { Text(status.rawValue) })
          .buttonStyle(.gradientStyle(config: .init(nsColor: .green)))
          .matchedGeometryEffect(id: "permission-overview-item", in: namespace)
      }
    }
  }
}

struct PermissionsOverview_Previews: PreviewProvider {
  static var previews: some View {
    PermissionsSettings()
      .frame(width: 360, height: 180)
  }
}
