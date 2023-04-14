import SwiftUI
import Inject

struct SidebarConfigurationView: View {
  enum Action {
    case selectConfiguration(ConfigurationViewModel.ID)
  }
  @EnvironmentObject private var publisher: ConfigurationPublisher

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      HStack {
        Menu {
          ForEach(publisher.models) { configuration in
            Button(action: { onAction(.selectConfiguration(configuration.id)) },
                   label: { Text(configuration.name) })
          }
        } label: {
          HStack {
            // TODO: Fix this!
            Text( publisher.models.first?.name ?? "Missing value" )
              .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
          }
          .fixedSize(horizontal: false, vertical: true)
          .allowsTightening(true)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Spacer()
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 4)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.disabledControlTextColor))
        }
      )

      Button(action: {}, label: {
        Image(systemName: "plus")
      })
      .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
    }
  }
}

struct SidebarConfigurationView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarConfigurationView { _ in }
      .designTime()
  }
}
