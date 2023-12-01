import Bonzai
import SwiftUI

struct AddUserModeView: View {
  @ObserveInjection var inject
  @State var name: String = ""
  let action: (String) -> Void

  var body: some View {
    Group {
      HStack {
        TextField("User Mode Name", text: $name)
          .onSubmit {
            action(name)
          }
        Button(action: {
          action(name)
        }, label: { Text("Done") })
        .buttonStyle(.regular)
      }
    }
    .enableInjection()
  }
}


#Preview {
  AddUserModeView(action: { _ in })
}
