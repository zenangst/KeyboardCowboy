import SwiftUI

struct WorkflowCommandEmptyListView: View {
  @Environment(\.openWindow) var openWindow
  @ObservedObject private var detailPublisher: DetailPublisher

  var namespace: Namespace.ID
  private var onAction: (SingleDetailView.Action) -> Void

  init(namespace: Namespace.ID, detailPublisher: DetailPublisher, onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.namespace = namespace
    self.detailPublisher = detailPublisher
    self.onAction = onAction
  }

  var body: some View {
    VStack {
      if detailPublisher.data.commands.isEmpty {
        Button(action: {
          openWindow(value: NewCommandWindow.Context.newCommand(workflowId: detailPublisher.data.id))
        }) {
          HStack {
            Image(systemName: "plus.app")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16, height: 16)
            Divider()
              .opacity(0.5)

            Text("Add a command")
          }
          .padding(.vertical, 4)
          .padding(.horizontal, 8)
        }
        .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGreen, hoverEffect: false)))
        .matchedGeometryEffect(id: "add-command-button", in: namespace, properties: .position)
      }
    }
    .dropDestination(for: DropItem.self) { items, location in
      var urls = [URL]()
      for item in items {
        switch item {
        case .text(let text):
          if let url = URL(string: text) {
            urls.append(url)
          }
        case .url(let url):
          urls.append(url)
        case .none:
          continue
        }
      }

      if !urls.isEmpty {
        onAction(.dropUrls(workflowId: detailPublisher.data.id, urls: urls))
        return true
      }
      return false
    }
    .frame(maxWidth: .infinity)
  }
}

struct WorkflowCommandEmptyListView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    WorkflowCommandEmptyListView(namespace: namespace, detailPublisher: DesignTime.detailPublisher) { _ in }
  }
}
