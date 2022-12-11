import SwiftUI

struct ApplicationCommandView: View {
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel

  var body: some View {
    CommandContainerView(
      isEnabled: $command.isEnabled,
      icon: {
        if let image = command.image {
          Image(nsImage: image)
            .resizable()
        }
      },
      content: {
        HStack(spacing: 8) {
          Menu(content: {
            Button("Open", action: {})
            Button("Close", action: {})
          }, label: {
            HStack(spacing: 4) {
              Text("Open")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .truncationMode(.middle)
                .allowsTightening(true)
              Image(systemName: "chevron.down")
                .opacity(0.5)
            }
            .padding(4)
          })
          .buttonStyle(.plain)
          .background(
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color(.disabledControlTextColor))
              .opacity(0.5)
          )
          Text(command.name)
            .font(.body)
            .bold()
          Spacer()
        }
      }, subContent: {
        HStack {
          Toggle("In background", isOn: .constant(false))
          Toggle("Hide when opening", isOn: .constant(false))
          Toggle("If not running", isOn: .constant(false))
        }
        .lineLimit(1)
        .allowsTightening(true)
        .truncationMode(.tail)
        .font(.caption)

      }, onAction: {

      })
    .enableInjection()
  }
}

struct ApplicationCommandView_Previews: PreviewProvider {
  static var previews: some View {
    ApplicationCommandView(command: .constant(DesignTime.applicationCommand))
      .designTime()
  }
}
