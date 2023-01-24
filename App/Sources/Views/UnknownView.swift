import SwiftUI

struct UnknownView: View {
  @Binding var command: DetailViewModel.CommandViewModel

  var body: some View {
    HStack {
      HStack {
        ZStack {
          Rectangle()
            .fill(Color(nsColor: .controlAccentColor).opacity(0.1))
          if let iconPath = command.iconPath {
            Image(nsImage: NSWorkspace.shared.icon(forFile: iconPath))
              .resizable()
              .aspectRatio(contentMode: .fit)
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
