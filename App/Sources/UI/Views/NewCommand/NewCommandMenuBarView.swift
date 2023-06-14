import SwiftUI

struct NewCommandMenuBarView: View {
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State var tokens = [MenuBarCommand.Token]()

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation

    if case .menuBar(let tokens) = payload.wrappedValue {
      _tokens = .init(initialValue: tokens)
    } else {
      print(payload)
      _tokens = .init(initialValue: [
        .pick("Foo")
      ])
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      Label(title: { Text("Menu Bar item:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())

      VStack {
        ScrollView {
          ForEach(tokens) { token in
            HStack {
              switch token {
              case .pick(let value):
                Text(value)
              case .toggle(let lhs, let rhs):
                Text("Either:") +
                Text("'\(lhs)'")
                  .bold() +
                Text(" or ") +
                Text("'\(rhs)'")
                  .bold()
              }
              Spacer()
              Button(action: {}, label: {
                Text("Remove")
              })
              .buttonStyle(.gradientStyle(config: .init(nsColor: .systemRed, grayscaleEffect: true)))
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        Divider()
        HStack {
          TextField(text: .constant(""), prompt: Text("Menu item"), label: {
            Text("foo")
          })
          .textFieldStyle(AppTextFieldStyle())

          Button(action: {}, label: {
            Text("Add")
          })
          .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen)))
        }
      }
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .fill(Color(.textBackgroundColor).opacity(0.25))
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct NewCommandMenuBarView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandMenuBarView(
      .constant(.menuBar(tokens: [
        .pick("View"),
        .pick("Navigators"),
        .toggle("Show Navigator", "Hide Navigator")
      ])),
      validation: .constant(.valid))
  }
}
