import SwiftUI

struct GroupListCell: View {
  let group: ViewKit.Group

  var body: some View {
    HStack {
      name
      Spacer()
      numberOfWorkflows
    }.padding()
  }
}

// MARK: - Subviews

private extension GroupListCell {
  var name: some View {
    Text(group.name)
      .foregroundColor(.primary)
  }

  var numberOfWorkflows: some View {
    Text("\(group.workflows.count)")
      .foregroundColor(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(Circle().fill(Color(.systemBlue)))
  }
}

// MARK: - Previews

struct GroupListCell_Previews: PreviewProvider {
    static var previews: some View {
      GroupListCell(group: ModelFactory().groupListCell())
    }
}
