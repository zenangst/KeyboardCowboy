import SwiftUI

struct DetailView: View {
  @ObserveInjection var inject
  enum Action {
    case singleDetailView(SingleDetailView.Action)
  }

  var focus: FocusState<AppFocus?>.Binding
  @EnvironmentObject var statePublisher: DetailStatePublisher
  @EnvironmentObject var detailPublisher: DetailPublisher
  private var onAction: (DetailView.Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       onAction: @escaping (DetailView.Action) -> Void) {
    self.focus = focus
    self.onAction = onAction
  }

  @ViewBuilder
  var body: some View {
    Group {
      switch statePublisher.data {
      case .empty:
        Text("Empty")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .allowsHitTesting(false)
          .debugEdit()
      case .single:
        SingleDetailView(
          focus,
          detailPublisher: detailPublisher, onAction: {
            onAction(.singleDetailView($0))
          })
      case .multiple(let viewModels):
        let limit = 5
        let count = viewModels.count
        MultiDetailView( count > limit ? Array(viewModels[0...limit-1]) : viewModels, count: count)
      }
    }
    .animation(.default, value: statePublisher.data)
    .background(
      Color(nsColor: .textBackgroundColor).ignoresSafeArea(edges: .all)
    )
  }
}

struct DetailView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    DetailView($focus) { _ in }
      .designTime()
      .frame(height: 650)
  }
}
