import SwiftUI
import ModelKit

public struct MainView: View {
  @EnvironmentObject var userSelection: UserSelection
  let applicationProvider: ApplicationProvider
  let commandController: CommandController
  let groupController: GroupController
  let keyboardShortcutController: KeyboardShortcutController
  let workflowController: WorkflowController
  let openPanelController: OpenPanelController
  @ObservedObject var searchController: SearchController
  @State private var searchText: String = ""

  public init(applicationProvider: ApplicationProvider,
              commandController: CommandController,
              groupController: GroupController,
              keyboardShortcutController: KeyboardShortcutController,
              openPanelController: OpenPanelController,
              searchController: SearchController,
              workflowController: WorkflowController) {
    self.applicationProvider = applicationProvider
    self.commandController = commandController
    self.groupController = groupController
    self.keyboardShortcutController = keyboardShortcutController
    self.openPanelController = openPanelController
    self.searchController = searchController
    self.workflowController = workflowController
  }

  public var body: some View {
    NavigationView {
      VStack(alignment: .leading) {
        SearchField(query: Binding(get: { searchText },
                                   set: { newSearchText in
                                    searchText = newSearchText
                                    searchController.action(.search(newSearchText))()
                                   }))
          .frame(height: 48)
          .padding(.horizontal, 12)
        GroupList(applicationProvider: applicationProvider,
                  commandController: commandController,
                  groupController: groupController,
                  keyboardShortcutController: keyboardShortcutController,
                  openPanelController: openPanelController,
                  workflowController: workflowController)
          .frame(minWidth: 225)
      }
    }
  }
}

// MARK: Extensions

private extension MainView {
  var searchContext: some View {
    SearchView(searchController: searchController)
  }
}

struct MainView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    Group {
      MainView(applicationProvider: ApplicationPreviewProvider().erase(),
               commandController: CommandPreviewController().erase(),
               groupController: GroupPreviewController().erase(),
               keyboardShortcutController: KeyboardShortcutPreviewController().erase(),
               openPanelController: OpenPanelPreviewController().erase(),
               searchController: SearchPreviewController().erase(),
               workflowController: WorkflowPreviewController().erase())
        .frame(width: 960, height: 620, alignment: .leading)

      MainView(applicationProvider: ApplicationPreviewProvider().erase(),
               commandController: CommandPreviewController().erase(),
               groupController: GroupPreviewController().erase(),
               keyboardShortcutController: KeyboardShortcutPreviewController().erase(),
               openPanelController: OpenPanelPreviewController().erase(),
               searchController: SearchPreviewController().erase(),
               workflowController: WorkflowPreviewController().erase())
        .frame(width: 960, height: 620, alignment: .leading)

      MainView(applicationProvider: ApplicationPreviewProvider().erase(),
               commandController: CommandPreviewController().erase(),
               groupController: GroupPreviewController().erase(),
               keyboardShortcutController: KeyboardShortcutPreviewController().erase(),
               openPanelController: OpenPanelPreviewController().erase(),
               searchController: SearchPreviewController().erase(),
               workflowController: WorkflowPreviewController().erase())
        .frame(width: 960, height: 620, alignment: .leading)
    }
  }
}
