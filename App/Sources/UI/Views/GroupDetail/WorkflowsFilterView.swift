import SwiftUI
import Bonzai

struct WorkflowsFilterView: View {
  @State private var searchTerm: String = ""
  @EnvironmentObject private var publisher: GroupDetailPublisher
  @Binding private var showAddButton: Bool
  private let namespace: Namespace.ID
  private let debounce: DebounceController<String>
  private var focus: FocusState<AppFocus?>.Binding
  private let onClear: () -> Void
  private let onAddWorkflow: () -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       showAddButton: Binding<Bool>,
       onClear: @escaping () -> Void,
       onChange: @escaping (String) -> Void,
       onAddWorkflow: @escaping () -> Void
  ) {
    _showAddButton = showAddButton
    self.namespace = namespace
    self.focus = focus
    self.onClear = onClear
    self.onAddWorkflow = onAddWorkflow
    self.debounce = DebounceController("", kind: .keyDown, milliseconds: 150, onUpdate: { snapshot in
      onChange(snapshot)
    })
  }

  var body: some View {
    HStack(spacing: 8) {
      Group {
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
      }
      .opacity(publisher.data.isEmpty ? 0 : 1)

      Button(action: {
        searchTerm = ""
        onClear()
      },
             label: { Text("Clear") })
      .buttonStyle(.calm(color: .systemGray, padding: .medium))
      .font(.caption2)
      .opacity(!searchTerm.isEmpty ? 1 : 0)

      if showAddButton {
        GroupDetailAddButton(namespace, onAction: { onAddWorkflow() })
      }
    }
  }
}

struct ContentListFilterView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  @Namespace static var namespace
  static var previews: some View {
    WorkflowsFilterView($focus, namespace: namespace, showAddButton: .constant(false), onClear: {}, onChange: { _ in }, onAddWorkflow: { })
    .designTime()
  }
}
