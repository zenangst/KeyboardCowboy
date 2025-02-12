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
    VStack(alignment: .center) {
      VStack {
        RoundedRectangle(cornerRadius: 4)
          .fill(gradient)
          .aspectRatio(1.54/1, contentMode: .fit)
          .frame(height: 170)
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
          }
          .overlay(alignment: .top) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .top
            }, set: { _ in
              notificationPlacement = .top
            }), label: {})
          }
          .overlay(alignment: .topTrailing) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .topTrailing
            }, set: { _ in
              notificationPlacement = .topTrailing
            }), label: {})
          }

          .overlay(alignment: .leading) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .leading
            }, set: { _ in
              notificationPlacement = .leading
            }), label: {})
          }

          .overlay(alignment: .trailing) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .trailing
            }, set: { _ in
              notificationPlacement = .trailing
            }), label: {})
          }

          .overlay(alignment: .bottomLeading) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .bottomLeading
            }, set: { _ in
              notificationPlacement = .bottomLeading
            }), label: {})
          }

          .overlay(alignment: .bottom) {
            Toggle(isOn: Binding(get: {
              notificationPlacement == .bottom
            }, set: { _ in
              notificationPlacement = .bottom
            }), label: {})
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
      .frame(maxWidth: .infinity)
      .padding()
      .roundedStyle(padding: 0)

      Grid(alignment: .leading) {
        GridRow {
          Toggle("Keyboard Commands", isOn: $keyboardCommands)
          Toggle("Running Workflows", isOn: $runningWorkflows)
          Toggle("Show Bundles", isOn: $bundles)
        }
      }
      .font(.caption2)
      .padding([.horizontal])
    }
    .frame(minWidth: 480, minHeight: 280, alignment: .top)
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

