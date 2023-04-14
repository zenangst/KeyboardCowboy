import SwiftUI

struct EditWorfklowGroupView: View {
  enum Action {
    case ok(WorkflowGroup)
    case cancel
  }

  @ObservedObject var applicationStore: ApplicationStore
  @State var editIcon: WorkflowGroup?
  @State var group: WorkflowGroup
  var action: (Action) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        WorkflowGroupIconView(group: $group, size: 48)
          .onTapGesture {
            editIcon = group
          }
          .popover(item: $editIcon, arrowEdge: .bottom, content: { _ in
            EditGroupIconView(group: $group)
          })
          .cornerRadius(24, antialiased: true)
        TextField("Name:", text: $group.name)
          .textFieldStyle(LargeTextFieldStyle())
          .onSubmit { action(.ok(group)) }
      }.padding()
      Divider()
      ScrollView {
        RuleListView(applicationStore: applicationStore,
                     group: $group)
        .padding()
        .background(Color(.windowBackgroundColor.withAlphaComponent(0.5)))
        .focusSection()
        
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading) {
            Text("Workflows in this group are only activated when the following applications are the frontmost app.")
            Text("The order of this list is irrelevant. If this list is empty, then the workflows are considered global.")
          }
          .fixedSize(horizontal: false, vertical: true)
          .font(.caption)
        }.padding()
      }

      Divider()

      HStack {
        Spacer()
        Group {
          Button(role: .cancel) {
            action(.cancel)
          } label: {
            Text("Cancel")
              .frame(minWidth: 40)
          }

          Button(action: { action(.ok(group)) }) {
            Text("OK")
              .frame(minWidth: 40)
          }
        }
      }
      .padding()
    }
    .frame(minWidth: 520, minHeight: 400)
  }
}

struct EditWorfklowGroupView_Previews: PreviewProvider {
  static let group = WorkflowGroup.designTime()
  static var previews: some View {
    EditWorfklowGroupView(
      applicationStore: ApplicationStore(),
      group: group,
      action: { _ in })
  }
}
