import SwiftUI

struct WorkflowList: View {
  static let idealWidth: CGFloat = 300
  @EnvironmentObject var userSelection: UserSelection
  var group: GroupViewModel?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      group.map { group in
        List(selection: $userSelection.workflow) {
          ForEach(group.workflows) { workflow in
            WorkflowListCell(workflow: workflow)
              .tag(workflow)
              .onTapGesture(count: 1, perform: { userSelection.workflow = workflow })
          }
        }
        .onAppear {
          if userSelection.workflow == nil {
            userSelection.workflow = group.workflows.first
          }
        }
      }
      addButton
    }
  }
}

private extension WorkflowList {
  var addButton: some View {
    HStack(spacing: 4) {
      RoundOutlinedButton(title: "+", color: Color(.controlAccentColor))
      Button("Add Workflow", action: {})
      .buttonStyle(PlainButtonStyle())
    }.padding(8)
  }
}

// MARK: - Previews

struct WorkflowList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowList(group: ModelFactory().groupList().first!)
      .frame(width: WorkflowList.idealWidth, height: 360)
      .environmentObject(UserSelection())
  }
}
