import SwiftUI

struct DetailView: View {
  enum Action {
    case singleDetailView(SingleDetailView.Action)
  }
  @EnvironmentObject var publisher: DetailPublisher
  @State var isFocused: Bool = false
  private var onAction: (DetailView.Action) -> Void

  init(onAction: @escaping (DetailView.Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    Group {
      switch publisher.model {
      case .empty:
        Text("Empty")
          .toolbar(content: {
            ToolbarItem {
              Text("Empty")
            }
          })
      case .single(let model):
        SingleDetailView(model, onAction: { onAction(.singleDetailView($0)) })
      case .multiple:
        Text("Multiple commands selected")
          .toolbar(content: {
            ToolbarItem {
              Text("Multiple commands selected")
            }
          })
      }
    }
    .id(publisher.model.id)
  }
}

struct DetailView_Previews: PreviewProvider {
  static var previews: some View {
    DetailView { _ in }
      .designTime()
  }
}
