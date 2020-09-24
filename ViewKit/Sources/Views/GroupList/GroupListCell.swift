import SwiftUI

struct GroupListCell: View {
  let group: ViewKit.GroupViewModel

  var body: some View {
    HStack {
      icon
      name
      Spacer()
      numberOfWorkflows
    }
    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 15))
    .frame(minHeight: 36, idealHeight: 36)
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

  var name: some View {
    Text(group.name)
      .foregroundColor(.primary)
  }

  var numberOfWorkflows: some View {
    Text("\(group.workflows.count)")
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
    GroupListCell(group: ModelFactory().groupListCell())
  }
}
