import SwiftUI

struct DetailView: View {
  @EnvironmentObject var publisher: DetailPublisher
  @State var isFocused: Bool = false

  var body: some View {
    Group {
      switch publisher.model {
      case .empty:
        Text("Empty")
      case .single(let model):
        SingleDetailView(model)
      case .multiple:
        Text("Multiple commands selected")
      }
    }.id(publisher.model.id)
  }
}

struct DetailView_Previews: PreviewProvider {
  static var previews: some View {
    DetailView()
      .designTime()
  }
}
