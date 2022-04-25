import SwiftUI

struct EditTypeView: View {
  @ObserveInjection var inject
  @Binding var command: TypeCommand

  init(command: Binding<TypeCommand>) {
    _command = command
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Type input").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        LazyVGrid(columns: [
          GridItem(.fixed(50), alignment: .topTrailing),
          GridItem(.flexible())
        ], content: {
          Text("Name:")
          TextField(command.name, text: Binding(get: {
            command.name
          }, set: {
            command = TypeCommand(id: command.id, name: $0,
                                  input: command.input)
          }))

          Text("Input:")
          TextEditor(text: Binding(get: {
            command.input
          }, set: {
            command = TypeCommand(id: command.id, name: command.name,
                                  input: $0)
          }))
          .frame(height: 320)
        })
      }
      .frame(alignment: .topLeading)
      .padding()
    }
    .enableInjection()
  }
}

struct EditTypeView_Previews: PreviewProvider {
  static var previews: some View {
    EditTypeView(command: .constant(TypeCommand.init(name: "", input: "")))
  }
}
