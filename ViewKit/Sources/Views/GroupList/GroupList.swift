import SwiftUI

public struct GroupList: View {
  public typealias Controller = AnyViewController<[GroupViewModel], Action>
  public enum Action {
    case createGroup
    case updateGroup(GroupViewModel)
    case deleteGroup(GroupViewModel)
    case dropFile(URL)
  }

  static let idealWidth: CGFloat = 300

  @EnvironmentObject var userSelection: UserSelection
  @ObservedObject var controller: Controller
  @State private var editGroup: GroupViewModel?

  var groups: [GroupViewModel] { controller.state }

  public init(controller: Controller) {
    self.controller = controller
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      list
        .onAppear {
          if userSelection.group == nil {
            userSelection.group = groups.first
          }
        }
        .onDrop(of: ["public.file-url"], isTargeted: nil, perform: { providers -> Bool in
          providers.forEach {
            _ = $0.loadObject(ofClass: URL.self) { url, _ in
              guard let url = url else { return }
              controller.action(.dropFile(url))()
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
  var header: some View {
    Text("Groups")
      .padding(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 0))
      .font(.subheadline)
      .foregroundColor(Color.secondary)
  }

  var list: some View {
    List(selection: $userSelection.group) {
      ForEach(groups) { group in
        GroupListCell(
          name: Binding(
            get: { group.name },
            set: { name in
              var group = group
              group.name = name
              controller.perform(.updateGroup(group))
            }
          ),
          count: group.workflows.count
        )
        .onTapGesture(count: 1, perform: {
          userSelection.group = group
        })
        .frame(maxWidth: .infinity, alignment: .leading)
        .contextMenu {
          Button("Edit") { editGroup = group }
          Button("Remove") { controller.action(.deleteGroup(group))() }
        }
        .tag(group)
      }
    }
    .frame(minHeight: 480)
    .sheet(item: $editGroup, content: editGroup)
  }

  var addButton: some View {
    Button("+ Add Group", action: {
      controller.perform(.createGroup)
    })
    .buttonStyle(PlainButtonStyle())
    .padding(.init(top: 0, leading: 8, bottom: 8, trailing: 0))
  }

  func editGroup(_ group: GroupViewModel) -> some View {
    EditGroup(
      name: group.name,
      editAction: { name in
        var group = group
        group.name = name
        controller.perform(.updateGroup(group))
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
    GroupList(controller: PreviewController().erase())
      .frame(width: GroupList.idealWidth, height: 480)
      .environmentObject(UserSelection())
  }
}

private final class PreviewController: ViewController {
  let state = ModelFactory().groupList()
  func perform(_ action: GroupList.Action) {}
}
