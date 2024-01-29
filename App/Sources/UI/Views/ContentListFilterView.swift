import SwiftUI
import Bonzai

struct ContentListFilterView: View {
  @State private var searchTerm: String = ""
  @EnvironmentObject private var publisher: ContentPublisher
  private let debounce: DebounceController<String>
  private var focus: FocusState<AppFocus?>.Binding
  private let onClear: () -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       onClear: @escaping () -> Void,
       onChange: @escaping (String) -> Void) {
    self.focus = focus
    self.onClear = onClear
    self.debounce = DebounceController("", kind: .keyDown, milliseconds: 150, onUpdate: { snapshot in
      onChange(snapshot)
    })
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
            onClear()
          })
          .onSubmit {
            focus.wrappedValue = .workflows
          }
          .frame(height: 24)
          .onChange(of: searchTerm, perform: { value in
            debounce.process(value)
          })
        if !searchTerm.isEmpty {
          Button(action: {
            searchTerm = ""
            onClear()
          },
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
    ContentListFilterView($focus, onClear: {}) { _ in }
    .designTime()
  }
}
