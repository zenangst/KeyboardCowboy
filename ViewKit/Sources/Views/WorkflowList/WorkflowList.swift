//
//  WorkflowList.swift
//  ViewKit
//
//  Created by Vadym Markov on 08/09/2020.
//

import SwiftUI

struct WorkflowList: View {
  static let idealWidth: CGFloat = 300
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
            WorkflowListCell(workflow: workflow)
          }
        }
        .onAppear(perform: {
          selection = workflows.first
        })
      }
      .frame(minWidth: 300, idealWidth: Self.idealWidth, maxWidth: 500, maxHeight: .infinity)
    }
  }
}

// MARK: - Previews

struct WorkflowList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowList(workflows: ModelFactory().workflowList())
  }
}
