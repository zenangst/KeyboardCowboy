import SwiftUI

struct SidebarConfigurationView: View {
  enum Action {
    case selectConfiguration(ConfigurationViewModel.ID)
  }
  @ObserveInjection var inject
  @EnvironmentObject private var publisher: ConfigurationPublisher

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      Menu {
        ForEach(publisher.models) { configuration in
          Button(action: { onAction(.selectConfiguration(configuration.id)) },
                 label: { Text(configuration.name) })
        }
      } label: {
        HStack {
          Text( publisher.selections.first?.name ?? "Missing value" )
            .lineLimit(1)
          Spacer()
          Image(systemName: "chevron.down")
        }
        .fixedSize(horizontal: false, vertical: true)
        .allowsTightening(true)
      }
      Spacer()
    }
    .padding(6)
    .background(
      ZStack {
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(.disabledControlTextColor))
      }
    )
    .buttonStyle(.plain)
    .enableInjection()
  }
}

struct SidebarConfigurationView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarConfigurationView { _ in }
      .designTime()
  }
}
