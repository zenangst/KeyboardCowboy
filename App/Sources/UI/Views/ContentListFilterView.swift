import SwiftUI
import Bonzai

struct ContentListFilterView: View {
  @Binding private var searchTerm: String
  @EnvironmentObject private var publisher: ContentPublisher
  private var focus: FocusState<AppFocus?>.Binding
  private var contentSelectionManager: SelectionManager<ContentViewModel>

  init(_ focus: FocusState<AppFocus?>.Binding,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       searchTerm: Binding<String>) {
    self.focus = focus
    self.contentSelectionManager = contentSelectionManager
    self._searchTerm = searchTerm
  }

  var body: some View {
    if !publisher.data.isEmpty {
      HStack(spacing: 8) {
        Image(systemName: searchTerm.isEmpty
              ? "line.3.horizontal.decrease.circle"
              : "line.3.horizontal.decrease.circle.fill")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .foregroundColor(Color(nsColor:ZenColorPublisher.shared.color.nsColor))
        .frame(width: 12)
        .padding(.leading, 8)
        TextField("Filter", text: $searchTerm)
          .textFieldStyle(
            .zen(.init(
              calm: true,
              color: ZenColorPublisher.shared.color,
              backgroundColor: Color(nsColor: .clear),
              font: .caption2,
              unfocusedOpacity: 0
              )
            )
          )
          .focused(focus, equals: .search)
          .onExitCommand(perform: {
            searchTerm = ""
          })
          .onSubmit {
            focus.wrappedValue = .workflows
          }
          .frame(height: 24)
        if !searchTerm.isEmpty {
          Button(action: { searchTerm = "" },
                 label: { Text("Clear") })
          .buttonStyle(.calm(color: .systemGray, padding: .medium))
          .font(.caption2)
        }
      }
      .padding(.horizontal, 8)
    } else {
      EmptyView()
    }
  }
}

struct ContentListFilterView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    ContentListFilterView($focus, 
                          contentSelectionManager: SelectionManager<ContentViewModel>(),
                          searchTerm: .constant("test"))
    .designTime()
  }
}
