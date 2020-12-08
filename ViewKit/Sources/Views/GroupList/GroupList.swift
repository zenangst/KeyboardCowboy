import SwiftUI
import ModelKit

public struct GroupList: View {
  public enum Action {
    case createGroup
    case updateGroup(ModelKit.Group)
    case deleteGroup(ModelKit.Group)
    case moveGroup(from: Int, to: Int)
    case dropFile([URL])
  }

  public enum SheetAction: Identifiable {
    case edit(ModelKit.Group)
    case delete(ModelKit.Group)

    public var id: String { return UUID().uuidString }
  }

  static let idealWidth: CGFloat = 300

  @EnvironmentObject var userSelection: UserSelection
  let applicationProvider: ApplicationProvider
  let factory: ViewFactory
  @ObservedObject var groupController: GroupController
  let workflowController: WorkflowController
  @State private var sheetAction: SheetAction?
  @State private var isDropping: Bool = false

  public var body: some View {
    List {
      ForEach(groupController.state, id: \.id) { group in
        NavigationLink(
          destination: factory.workflowList(group: group, selectedWorkflow: userSelection.workflow)
            .environmentObject(userSelection),
          tag: group, selection: Binding<ModelKit.Group?>(get: {
            userSelection.group
          }, set: { group in
            userSelection.group = group
            if let group = group {
              if let workflow = userSelection.workflow,
                 !group.workflows.contains(workflow) {
                userSelection.workflow = group.workflows.first
              } else if userSelection.workflow == nil {
                userSelection.workflow = group.workflows.first
              }
            }
          })) {
          GroupListCell(
            name: group.name,
            color: group.color,
            symbol: group.symbol,
            count: group.workflows.count,
            editAction: { sheetAction = .edit(group) }
          )
        }
        .frame(minHeight: 36)
        .contextMenu {
          Button("Show Info") { sheetAction = .edit(group) }
          Divider()
          Button("Delete", action: onDelete)
        }
      }
      .onInsert(of: []) { _, _ in }
      .onMove { indices, newOffset in
        for i in indices {
          groupController.action(.moveGroup(from: i, to: newOffset))()
        }
      }
    }
    .onDrop($isDropping) { groupController.perform(.dropFile($0)) }
    .border(Color.accentColor, width: isDropping ? 5 : 0)
    .onDeleteCommand(perform: onDelete)
    .toolbar(content: {
      ToolbarItemGroup(placement: .automatic) {
        Button(action: {
          groupController.perform(.createGroup)
        }, label: {
          Image(systemName: "folder.badge.plus")
            .renderingMode(.template)
            .foregroundColor(Color(.systemGray))
        })
        .help("Add new Group")
      }
    }).sheet(item: $sheetAction, content: { action in
      switch action {
      case .edit(let group):
        editGroup(group)
      case .delete(let group):
        VStack(spacing: 0) {
          Text("Are you sure you want to delete the group “\(group.name)”?")
            .padding()
          Divider()
          HStack {
            Button("Cancel", action: {
              sheetAction = nil
            }).keyboardShortcut(.cancelAction)
            Button("Delete", action: {
              sheetAction = nil
              groupController.perform(.deleteGroup(group))
            }).keyboardShortcut(.defaultAction)
          }.padding()
        }
      }
    })
  }
}

// MARK: - Subviews

private extension GroupList {
  func editGroup(_ group: ModelKit.Group) -> some View {
    EditGroup(
      name: group.name,
      color: group.color,
      symbol: group.symbol,
      bundleIdentifiers: group.rule?.bundleIdentifiers ?? [],
      applicationProvider: applicationProvider.erase(),
      editAction: { name, color, symbol, bundleIdentifers in
        var group = group
        group.name = name
        group.color = color
        group.symbol = symbol

        var rule = group.rule ?? Rule()

        if !bundleIdentifers.isEmpty {
          rule.bundleIdentifiers = bundleIdentifers
          group.rule = rule
        } else {
          group.rule = nil
        }

        groupController.perform(.updateGroup(group))
        sheetAction = nil
      },
      cancelAction: { sheetAction = nil })
  }

  func onDelete() {
    if let group = userSelection.group {
      if group.workflows.isEmpty {
        groupController.perform(.deleteGroup(group))
      } else {
        sheetAction = .delete(group)
      }
    }
  }
}

// MARK: - Previews

struct GroupList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    DesignTimeFactory().groupList()
      .environmentObject(UserSelection())
      .frame(width: GroupList.idealWidth)
  }
}
