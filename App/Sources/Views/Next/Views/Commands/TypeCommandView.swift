import SwiftUI

struct TypeCommandView: View {
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel
  @State var source: String

  init(command: Binding<DetailViewModel.CommandViewModel>) {
    _command = command
    _source = .init(initialValue: "")
  }

  var body: some View {
    CommandContainerView(
      isEnabled: $command.isEnabled,
      icon: {
        Rectangle()
          .fill(Color(nsColor: .controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        RegularKeyIcon(letter: "(...)")
      }, content: {
        ZStack(alignment: .leading) {
          TextEditor(text: $source)
            .font(.body)
            .padding(.top, 8)
            .scrollIndicators(.hidden)
          Text("Enter text...")
            .opacity(source.isEmpty ? 0.5 : 0)
            .allowsHitTesting(false)
            .padding(.leading, 4)
        }
      }, subContent: {
        EmptyView()
      }, onAction: {

      })
    .enableInjection()
  }
}

struct TypeCommandView_Previews: PreviewProvider {
  static var previews: some View {
    TypeCommandView(command: .constant(DesignTime.typeCommand))
  }
}
