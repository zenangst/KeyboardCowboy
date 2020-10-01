import SwiftUI

struct GroupListCell: View {
  typealias CommitHandler = (String, String) -> Void
  @State var internalName: String
  @Binding var name: String
  @Binding var color: String
  let count: Int
  let onCommit: CommitHandler

  init(name: Binding<String>,
       color: Binding<String>,
       count: Int,
       onCommit: @escaping CommitHandler) {
    _internalName = State(initialValue: name.wrappedValue)
    _name = name
    _color = color
    self.count = count
    self.onCommit = onCommit
  }

  var body: some View {
    HStack {
      icon
      textField
      Spacer()
      numberOfWorkflows
    }
    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
    .frame(minHeight: 36)
  }
}

// MARK: - Subviews

private extension GroupListCell {
  var icon: some View {
    ZStack {
      Circle().fill(Color(hex: color))
        .frame(width: 24, height: 24)
      Text("⌨️")
    }
  }

  var textField: some View {
    TextField(
      "",
      text: $internalName,
      onEditingChanged: { _ in },
      onCommit: {
        onCommit(internalName, color)
      })
      .foregroundColor(.primary)
      .lineSpacing(-2.0)
  }

  var numberOfWorkflows: some View {
    Text("\(count)")
      .foregroundColor(.secondary)
      .padding(.vertical, 2)
  }
}

// MARK: - Previews

struct GroupListCell_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let group = ModelFactory().groupListCell()
    return GroupListCell(name: .constant(group.name), color: .constant(group.color),
                         count: group.workflows.count, onCommit: { _, _ in })
  }
}
