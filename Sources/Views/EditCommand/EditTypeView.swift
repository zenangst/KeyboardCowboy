import SwiftUI

struct EditTypeView: View {
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
          GridItem(.fixed(50), alignment: .trailing),
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
          TextField(command.input, text: Binding(get: {
            command.input
          }, set: {
            command = TypeCommand(id: command.id, name: command.name,
                                  input: $0)
          }))
        })
      }.padding()
    }
  }
}

struct EditTypeView_Previews: PreviewProvider {
  static var previews: some View {
    EditTypeView(command: .constant(TypeCommand.init(name: "", input: "")))
  }
}
