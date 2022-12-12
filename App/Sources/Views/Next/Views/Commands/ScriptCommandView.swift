import SwiftUI

struct ScriptCommandView: View {
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel

  var body: some View {
    CommandContainerView(isEnabled: $command.isEnabled, icon: {
      Rectangle()
        .fill(Color(nsColor: .controlAccentColor).opacity(0.375))
        .cornerRadius(8, antialiased: false)

      if let image = command.image {
        Image(nsImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
      }

      VStack {
        Spacer()
        Group {
          if case .script(let kind) = command.kind,
             case .path(_, let fileExtension) = kind {
            Text(fileExtension)

          } else {
            Text("Inline")
          }
        }
        .font(.system(size: 8, weight: .semibold, design: .monospaced))
        .padding(2)
        .foregroundColor(.black)
        .background {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color(nsColor: .systemYellow))
        }
      }
      .offset(x: 2.5, y: -2.5)
    }, content: {
      HStack(spacing: 8) {
        Text(command.name)
          .allowsTightening(true)
          .font(.body)
          .bold()
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .truncationMode(.head)
        Spacer()
      }
    }, subContent: {
      HStack {
        if case .script(let kind) = command.kind {
          switch kind {
          case .inline:
            Button("Edit", action: { })
          case .path:
            Button("Open", action: { })
            Button("Reveal", action: { })
          }
        }
      }
      .font(.caption)
    }, onAction: {

    })
    .enableInjection()
  }
}

struct ScriptCommandView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      ScriptCommandView(command: .constant(DesignTime.scriptCommandInline))
        .frame(maxHeight: 80)
      Divider()
      ScriptCommandView(command: .constant(DesignTime.scriptCommandWithPath))
        .frame(maxHeight: 80)
    }
  }
}
