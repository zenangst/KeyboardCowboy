import SwiftUI
import ModelKit

public struct GroupList: View {
  public enum ViewState {
    case empty
    case hasContent([ModelKit.Group])
    case hasSelection(Workflow, [ModelKit.Group])
  }

  public enum Action {
    case createGroup
    case updateGroup(ModelKit.Group)
    case deleteGroup(ModelKit.Group)
    case moveGroup(from: Int, to: Int)
    case dropFile([URL])
  }

  public enum Sheet: Identifiable {
    case edit(ModelKit.Group)
    case delete(ModelKit.Group)

    public var id: String { return UUID().uuidString }
  }

  @StateObject var store: ViewKitStore
  @State private var sheet: Sheet?
  @State private var isDropping: Bool = false
  @AppStorage("groupSelection") var groupSelection: String?
  @AppStorage("workflowSelection") var workflowSelection: String?
  @AppStorage("workflowSelections") var workflowSelections: String?

  public var body: some View {
    List(selection: selection) {
      ForEach(store.groups) { group in
        GroupListView(group, editAction: { _ in
          sheet = .edit(group)
        })
        .id(UUID())
        .contextMenu {
          GroupListContextMenu(sheet: $sheet, group: group, deleteAction: { group in
            store.context.groups.perform(.deleteGroup(group))
          })
        }
      }
      .onMove(perform: { indices, newOffset in
        for i in indices {
          store.context.groups.perform(.moveGroup(from: i, to: newOffset))
        }
      })
      .onInsert(of: [], perform: { _, _ in })
    }
    .onDrop($isDropping) { urls in
      store.context.groups.perform(.dropFile(urls))
    }
    .onDeleteCommand(perform: {
      if let group = store.selectedGroup {
        if !group.workflows.isEmpty {
          sheet = .delete(group)
        } else {
          store.context.groups.perform(.deleteGroup(group))
        }
      }
    })
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.accentColor, lineWidth: isDropping ? 5 : 0)
        .padding(4)
    )
    .sheet(item: $sheet, content: { action in
      switch action {
      case .edit(let group):
        editGroup(group)
      case .delete(let group):
        deleteGroup(group)
      }
    })
  }
}

// MARK: Extensions

extension GroupList {
  var selection: Binding<String?> {
    Binding<String?>(get: {
      groupSelection
    }, set: { newValue in
      groupSelection = newValue
      if let group = store.groups.first(where: { $0.id == newValue }) {
        store.context.workflows.perform(.set(group: group))
        workflowSelection = group.workflows.first?.id
        workflowSelections = workflowSelection
      }
    })
  }

  func editGroup(_ group: ModelKit.Group) -> some View {
    EditGroup(
      name: group.name,
      color: group.color,
      symbol: group.symbol,
      bundleIdentifiers: group.rule?.bundleIdentifiers ?? [],
      applicationProvider: store.context.applicationProvider.erase(),
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

        store.context.groups.perform(.updateGroup(group))
        sheet = nil
      },
      cancelAction: { sheet = nil })
  }

  func deleteGroup(_ group: ModelKit.Group) -> some View {
    ConfirmView(
      config: .init(
        text: "Are you sure you want to delete the group “\(group.name)”?",
        confirmText: "Delete",
        confirmAction: {
          sheet = nil
          store.context.groups.perform(.deleteGroup(group))
        },
        cancelText: "Cancel",
        cancelAction: { sheet = nil }))
  }
}

// MARK: Previews

struct GroupList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    GroupList(store: .init(
      groups: ModelFactory().groupList(),
      context: .preview()
    ))
  }
}
