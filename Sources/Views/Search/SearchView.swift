import Apps
import SwiftUI

struct SearchView: View {
  @ObserveInjection var inject
  let applicationStore: ApplicationStore
  @ObservedObject private var searchStore: SearchStore
  @Namespace var namespace

  init(applicationStore: ApplicationStore, searchStore: SearchStore) {
    self.applicationStore = applicationStore
    self.searchStore = searchStore
  }

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(searchStore.results) { result in
          switch result.kind {
          case .workflow(let workflow):
            ResponderView("workflow-\(workflow.id)", namespace: namespace) { responder in
              WorkflowRowView(applicationStore: applicationStore,
                              workflow: .constant(workflow))
              .padding([.top, .bottom], 4)
              .padding([.leading, .trailing], 8)
              .frame(height: 40)
              .background(ResponderBackgroundView(responder: responder, cornerRadius: 8))
            }
          case .command(let command):
            ResponderView("command-\(command.id)", namespace: namespace) { responder in
              CommandView(command: .constant(command),
                          responder: responder, action: { _ in })
            }
          }
        }
      }
    }
    .enableInjection()
  }
}

struct SearchView_Previews: PreviewProvider {
  static var previews: some View {
    SearchView(
      applicationStore: applicationStore,
      searchStore: SearchStore(
        store: GroupStore(),
        results: [
          .init(name: "Workflow", kind: .workflow(Workflow.designTime(.application([])))),

            .init(
              name: "Finder",
              kind: .command(.application(.init(application: Application.finder())))),
          .init(
            name: "Calendar",
            kind: .command(.application(.init(application: Application.calendar()))))
        ]))
  }
}
