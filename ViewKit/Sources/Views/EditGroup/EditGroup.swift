import SwiftUI

struct EditGroup: View {
  @State var group: GroupViewModel
  var editAction: (GroupViewModel) -> Void
  var cancelAction: () -> Void

  var body: some View {
    HStack(alignment: .top) {
      icon
      VStack(alignment: .leading) {
        Text("\"\(group.name)\" info").bold()
        HStack {
          name
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

  var name: some View {
    Group {
      Text("Name:")
      TextField("", text: $group.name)
    }
  }

  var buttons: some View {
    HStack {
      Spacer()
      Button(action: cancelAction, label: {
        Text("Cancel").frame(minWidth: 60)
      })

      Button(action: { editAction(group) }, label: {
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
    EditGroup(group: GroupViewModel(id: UUID().uuidString, name: "Global shortcuts", workflows: []),
              editAction: { _ in },
              cancelAction: {})
      .frame(maxWidth: 450)
  }
}
