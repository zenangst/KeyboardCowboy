import SwiftUI

struct UnknownView: View {
  @Binding var command: DetailViewModel.CommandViewModel

  var body: some View {
    HStack {
      HStack {
        ZStack {
          Rectangle()
            .fill(Color(.controlAccentColor).opacity(0.1))
          if let icon = command.icon {
            IconView(icon: icon, size: CGSize(width: 32, height: 32))
          }
        }
        .frame(width: 32, height: 32)
        .cornerRadius(8, antialiased: false)

        Text(command.name)
      }
      Spacer()
      Toggle("", isOn: $command.isEnabled)
        .toggleStyle(.switch)
    }
    .padding(8)
    .background(.background)
    .cornerRadius(8)
  }
}
