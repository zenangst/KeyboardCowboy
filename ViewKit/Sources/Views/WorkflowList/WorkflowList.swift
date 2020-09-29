import SwiftUI

struct WorkflowList: View {
  static let idealWidth: CGFloat = 300
  @EnvironmentObject var userSelection: UserSelection
  @Binding var group: GroupViewModel?

  var body: some View {
    group.map { group in
      List(selection: $userSelection.workflow) {
        ForEach(group.workflows) { workflow in
          WorkflowListCell(workflow: workflow)
            .tag(workflow)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture(count: 1, perform: { userSelection.workflow = workflow })
        }
      }
      .onAppear {
        if userSelection.workflow == nil {
          userSelection.workflow = group.workflows.first
        }
      }
      .buttonStyle(PlainButtonStyle())
      .listStyle(PlainListStyle())
    }
  }
}

// MARK: - Previews

struct WorkflowList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowList(group: .constant(ModelFactory().groupList().first!))
      .frame(width: WorkflowList.idealWidth, height: 360)
      .environmentObject(UserSelection())
  }
}
