import SwiftUI
import ModelKit

struct EditGroup: View {
  @State private var showColorPopover = false
  @State private var hoverText: String = ""
  @State private var name: String
  @State private var color: String
  private var editAction: (String, String) -> Void
  private var cancelAction: () -> Void

  var firstRowColors: [String] = ["#EB5545", "#F2A23C", "#F9D64A", "#6BD35F", "#3984F7"]
  var secondRowColors: [String] = ["#B263EA", "#5D5FDE", "#A78F6D", "#98989D", "#EB4B63"]

  init(name: String,
       color: String,
       editAction: @escaping (String, String) -> Void,
       cancelAction: @escaping () -> Void) {
    _color = State(initialValue: color)
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
      ColorView($color, selectAction: { _ in
        showColorPopover = true
      })
        .frame(width: 64, height: 64)
      Text(hoverText)
        .allowsHitTesting(false)
        .foregroundColor(.white)
    }
    .onHover(perform: { hovering in
      hoverText = hovering ? "Edit" : ""
    })
    .popover(isPresented: $showColorPopover, content: {
      VStack(spacing: 8) {
        HStack(spacing: 8) {
          ForEach(firstRowColors, id: \.self) { color in
            ColorView(.constant(color), selectAction: selectColor)
          }
        }
        HStack(spacing: 8) {
          ForEach(secondRowColors, id: \.self) { color in
            ColorView(.constant(color), selectAction: selectColor)
          }
        }
      }.padding()
    })
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

      Button(action: { editAction(name, color) }, label: {
        Text("OK").frame(minWidth: 60)
      })
    }
  }

  func selectColor(_ newColor: String) {
    color = newColor
    showColorPopover = false
  }
}

struct EditGroup_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditGroup(
      name: "Global shortcuts",
      color: "#EB4B63",
      editAction: { _, _ in },
      cancelAction: {}
    )
    .frame(maxWidth: 450)
  }
}
