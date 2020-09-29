import SwiftUI

struct GroupListCell: View {
  @Binding var name: String
  let count: Int

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
      Circle().fill(Color(.systemBlue))
        .frame(width: 24, height: 24)
      Text("⌨️")
    }
  }

  var textField: some View {
    TextField("", text: $name)
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
    return GroupListCell(name: .constant(group.name), count: group.workflows.count)
  }
}
