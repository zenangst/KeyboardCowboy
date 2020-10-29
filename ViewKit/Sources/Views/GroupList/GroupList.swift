import SwiftUI
import ModelKit

public struct GroupList: View {
  public enum Action {
    case createGroup
    case updateGroup(ModelKit.Group)
    case deleteGroup(ModelKit.Group)
    case moveGroup(from: Int, to: Int)
    case dropFile(URL)
  }

  static let idealWidth: CGFloat = 300

  @EnvironmentObject var userSelection: UserSelection
  let applicationProvider: ApplicationProvider
  var commandController: CommandController
  @ObservedObject var groupController: GroupController
  let keyboardShortcutController: KeyboardShortcutController
  let openPanelController: OpenPanelController
  let workflowController: WorkflowController
  @State private var editGroup: ModelKit.Group?
  @State private var selection: ModelKit.Group?

  public var body: some View {
    List {
      ForEach(groupController.state, id: \.id) { group in
        NavigationLink(
          destination: WorkflowList(
            applicationProvider: applicationProvider,
            commandController: commandController,
            groupController: groupController,
            keyboardShortcutController: keyboardShortcutController,
            openPanelController: openPanelController,
            group: group,
            workflowController: workflowController),
          tag: group,
          selection: Binding<ModelKit.Group?>(
            get: { userSelection.group },
            set: {
              if userSelection.group?.id != $0?.id {
                userSelection.group = $0
              }
            }
          ),
          label: {
            GroupListCell(
              name: Binding(get: { group.name }, set: { name in
                var group = group
                group.name = name
                groupController.perform(.updateGroup(group))
              }),
              color: Binding(get: { group.color }, set: { color in
                var group = group
                group.color = color
              }),
              count: group.workflows.count,
              onCommit: { name, color in
                var group = group
                group.name = name
                group.color = color
                groupController.perform(.updateGroup(group))
              }
            )
            .onTapGesture(count: 2, perform: {
              editGroup = group
            })
            .id(group.id)
          }).contextMenu {
            Button("Show Info") { editGroup = group }
            Divider()
            Button("Delete") { groupController.action(.deleteGroup(group))() }
          }
      }.onMove(perform: { indices, newOffset in
        for i in indices {
          groupController.action(.moveGroup(from: i, to: newOffset))()
        }
      })
    }.sheet(item: $editGroup, content: editGroup)
  }
}

// MARK: - Subviews

private extension GroupList {
  var addButton: some View {
    HStack(spacing: 4) {
      RoundOutlinedButton(title: "+", color: Color(.secondaryLabelColor))
      Button("Add Group", action: {
        groupController.perform(.createGroup)
      })
      .buttonStyle(PlainButtonStyle())
    }.padding(8)
  }

  func editGroup(_ group: ModelKit.Group) -> some View {
    EditGroup(
      name: group.name,
      color: group.color,
      editAction: { name, color in
        var group = group
        group.name = name
        group.color = color
        groupController.perform(.updateGroup(group))
        editGroup = nil
      },
      cancelAction: { editGroup = nil })
  }
}

// MARK: - Previews

struct GroupList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    GroupList(
      applicationProvider: ApplicationPreviewProvider().erase(),
      commandController: CommandPreviewController().erase(),
      groupController: GroupPreviewController().erase(),
      keyboardShortcutController: KeyboardShortcutPreviewController().erase(),
      openPanelController: OpenPanelPreviewController().erase(),
      workflowController: WorkflowPreviewController().erase()
    )
      .frame(width: GroupList.idealWidth)
  }
}
