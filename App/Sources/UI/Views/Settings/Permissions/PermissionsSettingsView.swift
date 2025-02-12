import AXEssibility
import Bonzai
import Inject
import SwiftUI

struct PermissionsSettingsView: View {
  @ObserveInjection var inject
  @StateObject var accessibilityPermission = AccessibilityPermission.shared
  @StateObject var locationPermission = LocationPermission.shared

  var body: some View {
    VStack(spacing: 0) {
      ZenDivider()
      Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 32) {
        GridRow {
          PermissionOverviewItem(
            status: .readonly { accessibilityPermission.viewModel },
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
      .roundedSubStyle()
      .style(.derived)
      .style(.section(.content))

      Spacer()
    }
    .onChange(of: accessibilityPermission.permission, perform: { newValue in
      if newValue == .authorized {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          NSApplication.shared.keyWindow?.close()
        }
      }
    })
    .frame(minWidth: 480, maxWidth: 480)
  }
}

fileprivate struct PermissionOverviewItem: View {
  @Namespace var namespace
  @Binding var status: AccessibilityPermissionsItemStatus

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
          .matchedGeometryEffect(id: "permission-overview-item", in: namespace)
      }
    }
  }
}

struct PermissionsOverview_Previews: PreviewProvider {
  static var previews: some View {
    PermissionsSettingsView()
  }
}
