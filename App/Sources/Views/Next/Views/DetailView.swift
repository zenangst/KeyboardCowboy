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
      case .single(var model):
        SingleDetailView(
          Binding<DetailViewModel>(get: { model }, set: { model = $0 }),
          onAction: { onAction(.singleDetailView($0)) })
      case .multiple:
        Text("Multiple commands selected")
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
