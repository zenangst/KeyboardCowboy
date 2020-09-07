//
//  WorkflowList.swift
//  ViewKit
//
//  Created by Vadym Markov on 08/09/2020.
//

import SwiftUI

struct WorkflowList: View {
  let workflows: [Workflow]
  @State private var selection: Workflow?

  var body: some View {
    NavigationView {
      List {
        ForEach(workflows) { workflow in
          NavigationLink(
            destination: WorkflowView(workflow: workflow),
            tag: workflow,
            selection: $selection
          ) {
            HStack {
              VStack(alignment: .leading) {
                Text(workflow.name)
                  .foregroundColor(.primary)
                Text("\(workflow.commands.count) commands")
                  .foregroundColor(.secondary)
              }
              Spacer()
              Text("􀍟")
                .font(.title)
                .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
          }
        }
        .onAppear(perform: {
          selection = workflows.first
        })
      }
      .frame(minWidth: 200, idealWidth: 200, maxWidth: 300, maxHeight: .infinity)
    }
  }
}

// MARK: - Previews

struct WorkflowList_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowList(workflows: [
      Workflow(
        name: "Open Developer tools",
        combinations: [],
        commands: [
          Command(name: "Open instruments"),
          Command(name: "Open terminal")
        ]
      )
    ])
  }
}
