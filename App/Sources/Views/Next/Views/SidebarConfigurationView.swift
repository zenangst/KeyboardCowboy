import SwiftUI

struct SidebarConfigurationView: View {
  @ObserveInjection var inject
  @EnvironmentObject private var configurationPublisher: ConfigurationPublisher
  @State var presentingPopover: Bool = false

  var body: some View {
    Button(action: {
      withAnimation(.interactiveSpring()) {
        presentingPopover.toggle()
      }
    }) {
      HStack {
        Text(configurationPublisher.selections.first?.name ?? "Missing value")
          .lineLimit(1)
        Spacer()
        Divider()
        Image(systemName: "chevron.down")
          .rotationEffect(presentingPopover ? .degrees(180) : .zero)
      }
      .fixedSize(horizontal: false, vertical: true)
      .allowsTightening(true)
    }
    .transform(KCButtonStyle.modifiers) // Use the modifiers to not break keyboard shortcuts
    .enableInjection()
  }
}

struct SidebarConfigurationView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarConfigurationView()
      .designTime()
  }
}
