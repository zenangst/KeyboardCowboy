import SwiftUI
import Bonzai

struct WorkflowCommandEmptyListView: View {
  @Environment(\.openWindow) var openWindow

  private let namespace: Namespace.ID
  private let workflowId: String
  private let isPrimary: Binding<Bool>
  private let onAction: (SingleDetailView.Action) -> Void

  init(namespace: Namespace.ID, 
       workflowId: String,
       isPrimary: Binding<Bool>,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.isPrimary = isPrimary
    self.workflowId = workflowId
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    VStack {
      Button(action: {
        openWindow(value: NewCommandWindow.Context.newCommand(workflowId: workflowId))
      }) {
        HStack {
          Image(systemName: "plus.app")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
          Divider()
            .opacity(0.5)

          Text("Add Command")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
      }
      .buttonStyle(.zen(.init(color: .systemGreen,
                              grayscaleEffect: .readonly(!isPrimary.wrappedValue),
                              hoverEffect: .readonly(!isPrimary.wrappedValue))))
      .fixedSize()
      .matchedGeometryEffect(id: "add-command-button", in: namespace, properties: .position)
    }
    .padding()
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
        onAction(.dropUrls(workflowId: workflowId, urls: urls))
        return true
      }
      return false
    }
    .frame(maxWidth: .infinity)
    .matchedGeometryEffect(id: "command-list", in: namespace)
  }
}

struct WorkflowCommandEmptyListView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    WorkflowCommandEmptyListView(namespace: namespace, workflowId: UUID().uuidString, isPrimary: .constant(true)) { _ in }
      .designTime()
  }
}
