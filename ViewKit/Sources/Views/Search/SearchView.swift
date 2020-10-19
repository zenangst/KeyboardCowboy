import SwiftUI
import ModelKit

struct SearchView: View {
  @ObservedObject var searchController: SearchController

  var body: some View {
    ScrollView {
      HStack {
        Text("Search results").font(.title)
        Spacer()
      }
      Divider()

      if !searchController.state.workflows.isEmpty {
        HStack {
          HeaderView(title: "Workflows")
          Spacer()
        }

        ForEach(searchController.state.workflows) { workflow in
          WorkflowListCell(workflow: workflow)
            .frame(height: 48)
            .padding(.horizontal, 10)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(8)
            .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
            .onTapGesture {
              searchController.perform(.selectWorkflow(workflow))
            }
            .tag(workflow)
        }
        Divider()
      }

      if !searchController.state.commands.isEmpty {
        HStack {
          HeaderView(title: "Commands")
          Spacer()
        }
        ForEach(searchController.state.commands) { command in
          CommandView(command: command,
                      editAction: { _ in },
                      revealAction: { _ in },
                      runAction: { _ in },
                      showContextualMenu: false)
            .frame(height: 48)
            .padding(.horizontal, 10)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(8)
            .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
            .onTapGesture {
              searchController.perform(.selectCommand(command))
            }
            .tag(command)
        }
      }
    }.padding()
  }
}

struct SearchView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    SearchView(searchController: SearchPreviewController(
                state: SearchResults(
                  groups: ModelFactory().groupList(),
                  workflows: ModelFactory().workflowList(),
                  commands: ModelFactory().commands())
    ).erase())
  }
}
