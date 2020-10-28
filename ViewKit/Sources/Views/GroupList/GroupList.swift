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
  @ObservedObject var groupController: GroupController
  @State private var editGroup: ModelKit.Group?

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HeaderView(title: "Groups").padding(.bottom, 8)
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
      list
        .onDrop(of: ["public.file-url"], isTargeted: nil, perform: { providers -> Bool in
          providers.forEach {
            _ = $0.loadObject(ofClass: URL.self) { url, _ in
              guard let url = url else { return }
              groupController.action(.dropFile(url))()
            }
          }
          return true
        })
        .listStyle(SidebarListStyle())
      addButton
    }
  }
}

// MARK: - Subviews

private extension GroupList {
  var list: some View {
    List(selection: $userSelection.group) {
      ForEach(groupController.state, id: \.self) { group in
        GroupListCell(
          name: Binding(get: { group.name }, set: { name in
            var group = group
            group.name = name
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
        .contextMenu {
          Button("Show Info") { editGroup = group }
          Divider()
          Button("Delete") { groupController.action(.deleteGroup(group))() }
        }
        .fixedSize(horizontal: false, vertical: true)
        .tag(group)
      }.onMove(perform: { indices, newOffset in
        for i in indices {
          groupController.action(.moveGroup(from: i, to: newOffset))()
        }
      })
    }
    .frame(minHeight: 480)
    .sheet(item: $editGroup, content: editGroup)
  }

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
        userSelection.group = group
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
    GroupList(groupController: GroupPreviewController().erase())
      .frame(width: GroupList.idealWidth)
      .environmentObject(UserSelection())
  }
}

private final class PreviewController: ViewController {
  let state = ModelFactory().groupList()
  func perform(_ action: GroupList.Action) {}
}
