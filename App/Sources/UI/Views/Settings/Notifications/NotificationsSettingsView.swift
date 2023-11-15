import Bonzai
import SwiftUI

struct NotificationsSettingsView: View {
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
            ZenCheckbox(config: .init(color: .accentColor), isOn: Binding(get: {
              notificationPlacement == .topLeading
            }, set: { _ in
              notificationPlacement = .topLeading
            }))
              .padding(8)
          }

          .overlay(alignment: .top) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: Binding(get: { 
              notificationPlacement == .top
            }, set: { _ in
              notificationPlacement = .top
            }))
              .padding(8)
          }

          .overlay(alignment: .topTrailing) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: Binding(get: {
              notificationPlacement == .topTrailing
            }, set: { _ in
              notificationPlacement = .topTrailing
            }))
              .padding(8)
          }

          .overlay(alignment: .leading) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: Binding(get: {
              notificationPlacement == .leading
            }, set: { _ in
              notificationPlacement = .leading
            }))
              .padding(8)
          }

          .overlay(alignment: .trailing) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: Binding(get: {
              notificationPlacement == .trailing
            }, set: { _ in
              notificationPlacement = .trailing
            }))
              .padding(8)
          }

          .overlay(alignment: .bottomLeading) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: Binding(get: {
              notificationPlacement == .bottomLeading
            }, set: { _ in
              notificationPlacement = .bottomLeading
            }))
              .padding(8)
          }

          .overlay(alignment: .bottom) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: Binding(get: {
              notificationPlacement == .bottom
            }, set: { _ in
              notificationPlacement = .bottom
            }))
              .padding(8)
          }

          .overlay(alignment: .bottomTrailing) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: Binding(get: {
              notificationPlacement == .bottomTrailing
            }, set: { _ in
              notificationPlacement = .bottomTrailing
            }))
              .padding(8)
          }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .roundedContainer()

      Grid(alignment: .leading) {
        GridRow {
          ZenToggle(isOn: $keyboardCommands)
          Text("Keyboard Commands")
          ZenToggle(isOn: $runningWorkflows)
          Text("Running Workflows")
          ZenToggle(isOn: $bundles)
          Text("Show bundles")
        }
      }
      .font(.caption2)
      .padding([.horizontal, .top])
    }
    .frame(minWidth: 480, minHeight: 300, alignment: .top)
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

