import ModelKit
import SwiftUI

struct DetailViewToolbar: ToolbarContent {
  @Binding var config: DetailToolbarConfig
  @Binding var sheet: CommandListView.Sheet?
  let workflowName: String
  let searchController: SearchController

  var body: some ToolbarContent {
    ToolbarItemGroup {
      Spacer()
      SearchField(query: Binding<String>(
                    get: { config.searchQuery },
                    set: {
                      config.searchQuery = $0
                      searchController.perform(.search($0))
                      config.showSearch = !$0.isEmpty
                    }))
        .frame(minWidth: 100, idealWidth: 200, maxWidth: .infinity)
        .padding(.horizontal, 12)
        .popover(isPresented: $config.showSearch, arrowEdge: .bottom, content: {
          SearchView(searchController: searchController)
            .frame(width: 300, alignment: .center)
            .frame(minHeight: 300, maxHeight: 500)
        })

      Button(action: {
        sheet = .create(Command.empty(.application))
      },
      label: {
        Image(systemName: "plus.app")
          .renderingMode(.template)
          .foregroundColor(Color(.systemGray))
      })
      .help("Add Command to \"\(workflowName)\"")
    }
  }

  func toggleSidebar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(
      #selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
  }
}
