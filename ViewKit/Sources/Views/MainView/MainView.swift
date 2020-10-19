import SwiftUI
import ModelKit

public typealias GroupController = AnyViewController<[ModelKit.Group], GroupList.Action>
public typealias WorkflowController = AnyViewController<Workflow?, WorkflowList.Action>
public typealias CommandController = AnyViewController<[Command], CommandListView.Action>
public typealias OpenPanelController = AnyViewController<String, OpenPanelAction>
public typealias KeyboardShortcutController = AnyViewController<[ModelKit.KeyboardShortcut],
                                                                KeyboardShortcutListView.Action>
public typealias ApplicationProvider = AnyStateController<[Application]>
public typealias SearchController = AnyViewController<ModelKit.SearchResults, SearchResultsList.Action>

public struct MainView: View {
  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var commandController: CommandController
  @ObservedObject var groupController: GroupController
  @ObservedObject var keyboardShortcutController: KeyboardShortcutController
  @ObservedObject var workflowController: WorkflowController
  @ObservedObject var openPanelController: OpenPanelController
  @ObservedObject var searchController: SearchController
  @EnvironmentObject var userSelection: UserSelection
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
      sidebar.frame(minWidth: 200)
      GeometryReader { geometry in
        if userSelection.group != nil && userSelection.workflow != nil {
          HSplitView {
            workflowList
              .frame(minWidth: 225, maxWidth: 275)
              .frame(height: geometry.size.height)
              .padding(.top, 1)
            workflowDetail
              .frame(minWidth: 400, maxWidth: .infinity)
              .frame(height: geometry.size.height)
              .edgesIgnoringSafeArea(.top)
              .background(LinearGradient(
                            gradient:
                              Gradient(colors: [Color(.clear),
                                                Color(.gridColor).opacity(0.5)]),
                            startPoint: .top,
                            endPoint: .bottom))
          }
        } else if !searchText.isEmpty {
          searchContext
        } else if userSelection.workflow == nil {
          HStack {
            Spacer()
            HelperView(
              text: "Start by adding a workflow",
              contentView: Group {
                HStack {
                  RoundOutlinedButton(title: "+", color: Color(.secondaryLabelColor))
                  Button("Add Workflow", action: {
                    workflowController.perform(.createWorkflow)
                  }).buttonStyle(PlainButtonStyle())
                }
              }.erase())
              .frame(height: geometry.size.height)
            Spacer()
          }.padding()
        }
      }
    }.frame(minWidth: 845)
  }
}

// MARK: Extensions

private extension MainView {
  var sidebar: some View {
    VStack(alignment: .leading) {
      SearchField(query: Binding(get: { searchText },
                                 set: { newSearchText in
                                  searchText = newSearchText
                                  userSelection.group = nil
                                  userSelection.workflow = nil
                                  searchController.action(.search(newSearchText))()
      }))
        .frame(height: 48)
        .padding(.horizontal, 12)
        .padding(.top, 36)
      GroupList(controller: groupController)
    }.edgesIgnoringSafeArea(.top)
  }

  @ViewBuilder
  var workflowList: some View {
      if let group = userSelection.group,
         !group.workflows.isEmpty {
        WorkflowList(group: Binding(
                      get: { group },
                      set: { userSelection.group = $0 }),
                     workflowController: workflowController)
      }
  }

  @ViewBuilder
  var workflowDetail: some View {
    if let workflow = userSelection.workflow {
      WorkflowView(
        applicationProvider: applicationProvider,
        commandController: commandController,
        keyboardShortcutController: keyboardShortcutController,
        openPanelController: openPanelController,
        workflow:
          Binding(
            get: { workflow },
            set: { workflow in
              workflowController.action(.updateWorkflow(workflow))()
            }))
        .edgesIgnoringSafeArea(.top)
    } else {
      VStack {
        Text("Select a workflow").padding()
      }
    }
  }

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
        .environmentObject(UserSelection())
        .frame(width: 960, height: 600, alignment: .leading)
    }
  }
}
