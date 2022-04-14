import SwiftUI

struct AutoCompletionView: View {
  @ObservedObject private var iO = Inject.observer
  @ObservedObject var store: AutoCompletionStore

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(store.completions, id: \.self) { completion in
          HStack {
            Text(completion)
            Spacer()
          }
          .font(.caption.monospaced())
          .padding(4)
          .background(store.selection == completion
                      ? Color.accentColor.opacity(0.5)
                      : Color.clear)
          .cornerRadius(4)
          .frame(height: 16)
        }
      }
    }
    .padding(4)
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(Color(nsColor: .controlColor))
    )
    .cornerRadius(4)
    .enableInjection()
  }
}

struct AutoCompletionView_Previews: PreviewProvider {
    static var previews: some View {
      AutoCompletionView(store: Self.autoCompletionStore([
        "foo", "bar", "baz"
      ], selection: "foo"))
    }
}
