import SwiftUI
import ModelKit

public struct MainView: View {
  @EnvironmentObject var userSelection: UserSelection
  let factory: ViewFactory
  @ObservedObject var searchController: SearchController
  @State private var searchText: String = ""

  public init(factory: ViewFactory, searchController: SearchController) {
    self.factory = factory
    self.searchController = searchController
  }

  public var body: some View {
    NavigationView {
      VStack(alignment: .leading) {
        SearchField(query: Binding(
                      get: { searchText },
                      set: { newSearchText in
                        searchText = newSearchText
                        searchController.action(.search(newSearchText))()
                      }))
          .frame(height: 48)
          .padding(.horizontal, 12)
        factory.groupList()
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
    DesignTimeFactory().mainView()
      .environmentObject(UserSelection(
                          group: ModelFactory().groupList().first!,
                          workflow: ModelFactory().groupList().first!.workflows.first))
      .frame(width: 960, height: 620, alignment: .leading)
  }
}
