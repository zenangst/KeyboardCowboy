import SwiftUI
import ZenViewKit

struct NotificationsSettingsView: View {
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
            ZenCheckbox(config: .init(color: .accentColor), isOn: .constant(false))
              .padding(8)
          }

          .overlay(alignment: .top) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: .constant(false))
              .padding(8)
          }

          .overlay(alignment: .topTrailing) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: .constant(false))
              .padding(8)
          }

          .overlay(alignment: .leading) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: .constant(false))
              .padding(8)
          }

          .overlay(alignment: .trailing) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: .constant(false))
              .padding(8)
          }

          .overlay(alignment: .bottomLeading) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: .constant(false))
              .padding(8)
          }

          .overlay(alignment: .bottom) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: .constant(false))
              .padding(8)
          }

          .overlay(alignment: .bottomTrailing) {
            ZenCheckbox(config: .init(color: .accentColor), isOn: .constant(false))
              .padding(8)
          }
      }
      .frame(maxWidth: .infinity)
      .padding(16)
      .background(Color(.windowBackgroundColor))

      Grid(alignment: .leading) {
        GridRow {
          ZenToggle(isOn: .constant(false))
          Text("Keyboard Commands")
          ZenToggle(isOn: .constant(false))
          Text("Running Workflows")
          ZenToggle(isOn: .constant(false))
          Text("Show bundles")
        }
      }
      .font(.caption2)
      .padding([.horizontal, .top])
    }
    .frame(minWidth: 480, minHeight: 270, alignment: .top)
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

