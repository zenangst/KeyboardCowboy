import SwiftUI

struct EditGroup: View {
  @State private var name: String
  private var editAction: (String) -> Void
  private var cancelAction: () -> Void

  init(name: String, editAction: @escaping (String) -> Void, cancelAction: @escaping () -> Void) {
    _name = State(initialValue: name)
    self.editAction = editAction
    self.cancelAction = cancelAction
  }

  var body: some View {
    HStack(alignment: .top) {
      icon
      VStack(alignment: .leading) {
        Text("\"\(name)\" info").bold()
        HStack {
          nameView
        }
        buttons
      }.padding(.horizontal)
    }.padding()
  }
}

private extension EditGroup {
  var icon: some View {
    ZStack {
      Circle().fill(Color(.systemPurple))
        .frame(width: 64, height: 64)
      Text("")
    }
  }

  var nameView: some View {
    Group {
      Text("Name:")
      TextField("", text: $name)
    }
  }

  var buttons: some View {
    HStack {
      Spacer()
      Button(action: cancelAction, label: {
        Text("Cancel").frame(minWidth: 60)
      })

      Button(action: { editAction(name) }, label: {
        Text("OK").frame(minWidth: 60)
      })
    }
  }
}

struct EditGroup_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditGroup(
      name: "Global shortcuts",
      editAction: { _ in },
      cancelAction: {}
    )
    .frame(maxWidth: 450)
  }
}
