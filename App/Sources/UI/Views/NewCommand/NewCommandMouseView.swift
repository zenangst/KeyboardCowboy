import Bonzai
import SwiftUI

struct NewCommandMouseView: View {
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation
  @State var selection: MouseCommand.Kind = .click(.focused(.center))

  var body: some View {
    Text("Mouse Command")
      .font(.system(.body, design: .rounded,weight: .semibold))
      .allowsTightening(true)
      .lineLimit(1)
      .foregroundColor(Color.secondary)
      .frame(height: 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .overlay(alignment: .trailing) {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .fill(Color(nsColor: .systemYellow))
          .betaFeature("Mouse Commands is currently in beta. If you have any feedback, please reach out to us.") {
            Text("BETA")
              .foregroundStyle(Color.black)
              .font(.caption2)
              .frame(maxWidth: .infinity)
          }
          .frame(width: 32)
      }

    HStack {
      MouseIconView(size: 24)
      Menu(content: {
        ForEach(MouseCommand.Kind.allCases) { kind in
          Button(action: {
            selection = kind
          }, label: {
            Text(kind.displayValue)
          })
        }
      }, label: {
        Text(selection.displayValue)
      })
      .onChange(of: selection, perform: { value in
        payload = .mouse(kind: selection)
      })
      .onAppear {
        validation = .valid
        payload = .mouse(kind: selection)
      }
      .menuStyle(.regular)
    }
  }
}

struct NewCommandMouseView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .mouse,
      payload: .placeholder,
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
