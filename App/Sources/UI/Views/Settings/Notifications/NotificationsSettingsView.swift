import Bonzai
import Inject
import SwiftUI

struct NotificationsSettingsView: View {
  @ObserveInjection var inject
  @AppStorage("Notifications.KeyboardCommands") var keyboardCommands: Bool = false
  @AppStorage("Notifications.RunningWorkflows") var runningWorkflows: Bool = false
  @AppStorage("Notifications.Bundles") var bundles: Bool = false
  @AppStorage("Notifications.Placement") var notificationPlacement: NotificationPlacement = .bottomTrailing

  var body: some View {
    VStack(alignment: .center, spacing: 8) {
      VStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 4)
          .fill(gradient)
          .aspectRatio(1.54 / 1, contentMode: .fit)
          .frame(height: 180)
          .overlay(content: {
            Text("Notification Placement")
              .font(.caption2)
          })
          .overlay(alignment: .topLeading) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .topLeading
            }, set: { _ in
              notificationPlacement = .topLeading
            }), label: {})
              .padding(8)
          }
          .overlay(alignment: .top) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .top
            }, set: { _ in
              notificationPlacement = .top
            }), label: {})
              .padding(8)
          }
          .overlay(alignment: .topTrailing) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .topTrailing
            }, set: { _ in
              notificationPlacement = .topTrailing
            }), label: {})
              .padding(8)
          }
          .overlay(alignment: .leading) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .leading
            }, set: { _ in
              notificationPlacement = .leading
            }), label: {})
              .padding(8)
          }
          .overlay(alignment: .trailing) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .trailing
            }, set: { _ in
              notificationPlacement = .trailing
            }), label: {})
              .padding(8)
          }
          .overlay(alignment: .bottomLeading) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .bottomLeading
            }, set: { _ in
              notificationPlacement = .bottomLeading
            }), label: {})
              .padding(8)
          }
          .overlay(alignment: .bottom) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .bottom
            }, set: { _ in
              notificationPlacement = .bottom
            }), label: {})
              .padding(8)
          }
          .overlay(alignment: .bottomTrailing) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .bottomTrailing
            }, set: { _ in
              notificationPlacement = .bottomTrailing
            }), label: {})
              .padding(8)
          }
      }
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity)
      .roundedStyle(padding: 4)
      .style(.derived)

      Grid(alignment: .leading) {
        GridRow {
          Toggle("Keyboard Commands", isOn: $keyboardCommands)
          Toggle("Running Workflows", isOn: $runningWorkflows)
          Toggle("Show Bundles", isOn: $bundles)
        }
        .frame(maxWidth: .infinity)
      }
      .switchStyle()
      .font(.caption2)
      .roundedSubStyle()
      .style(.derived)
    }
    .style(.derived)
    .enableInjection()
  }

  private var gradient: LinearGradient {
    LinearGradient(stops: [
      .init(color: Color(.controlAccentColor.withSystemEffect(.deepPressed)), location: 0.0),
      .init(color: Color(.controlAccentColor), location: 0.5),
      .init(color: Color(.controlAccentColor.withSystemEffect(.disabled)), location: 1.0),
    ], startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}

struct NotificationsSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NotificationsSettingsView()
  }
}
