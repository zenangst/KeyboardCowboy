import SwiftUI

struct DetailView: View {
  enum Action {
    case singleDetailView(SingleDetailView.Action)
  }
  @EnvironmentObject var statePublisher: DetailStatePublisher
  @EnvironmentObject var detailPublisher: DetailPublisher
  @State var isFocused: Bool = false
  private var onAction: (DetailView.Action) -> Void

  init(onAction: @escaping (DetailView.Action) -> Void) {
    self.onAction = onAction
  }

  @ViewBuilder
  var body: some View {
    switch statePublisher.model {
    case .empty:
      Text("Empty")
    case .single:
      SingleDetailView(detailPublisher, onAction: {
        onAction(.singleDetailView($0))
      })
    case .multiple:
      Text("Multiple commands selected")
    }
  }
}

struct DetailView_Previews: PreviewProvider {
  static var previews: some View {
    DetailView { _ in }
      .designTime()
  }
}
