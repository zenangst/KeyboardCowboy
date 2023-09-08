import SwiftUI

struct ContentListFilterView: View {
  @EnvironmentObject private var publisher: ContentPublisher
  private var focus: FocusState<AppFocus?>.Binding
  private var contentSelectionManager: SelectionManager<ContentViewModel>
  @Binding var searchTerm: String

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
        .foregroundColor(contentSelectionManager.selectedColor)
        .frame(width: 12)
        .padding(.leading, 8)
        TextField("Filter", text: $searchTerm)
          .textFieldStyle(AppTextFieldStyle(.caption2,
                                            unfocusedOpacity: 0,
                                            color: contentSelectionManager.selectedColor))
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
          .buttonStyle(AppButtonStyle(.init(nsColor: .systemGray)))
          .font(.caption2)
        }
      }
      .padding(.horizontal, 8)
    } else {
      EmptyView()
    }
  }
}

