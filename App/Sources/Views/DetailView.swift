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
    Group {
      switch statePublisher.model {
      case .empty:
        Text("Empty")
      case .single:
        SingleDetailView(detailPublisher, onAction: {
          onAction(.singleDetailView($0))
        })
      case .multiple(let viewModels):
        let limit = 5
        let count = viewModels.count
        MultiDetailView( count > limit ? Array(viewModels[0...limit-1]) : viewModels, count: count)
      }
    }
    .animation(.default, value: statePublisher.model)
  }
}

struct DetailView_Previews: PreviewProvider {
  static var previews: some View {
    DetailView { _ in }
      .designTime()
  }
}
