import Bonzai
import Inject
import SwiftUI

struct WorkflowsFilterView: View {
  @ObserveInjection var inject
  @State private var searchTerm: String = ""
  @EnvironmentObject private var publisher: GroupDetailPublisher
  private let namespace: Namespace.ID
  private let debounce: DebounceController<String>
  private var focus: FocusState<AppFocus?>.Binding
  private let onClear: () -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       onClear: @escaping () -> Void,
       onChange: @escaping (String) -> Void)
  {
    self.namespace = namespace
    self.focus = focus
    self.onClear = onClear
    debounce = DebounceController("", kind: .keyDown, milliseconds: 150, onUpdate: { snapshot in
      onChange(snapshot)
    })
  }

  var body: some View {
    HStack(spacing: 6) {
      Group {
        Image(systemName: searchTerm.isEmpty
          ? "line.3.horizontal.decrease.circle"
          : "line.3.horizontal.decrease.circle.fill")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundColor(ColorPublisher.shared.color)
          .frame(width: 12)
        TextField("Filter", text: $searchTerm)
          .environment(\.textFieldCalm, true)
          .environment(\.textFieldForegroundColor, ColorPublisher.shared.color)
          .environment(\.textFieldFont, .caption2)
          .environment(\.textFieldPadding, .small)
          .environment(\.textFieldUnfocusedOpacity, 0)
          .focused(focus, equals: .search)
          .onExitCommand(perform: {
            searchTerm = ""
            onClear()
          })
          .onSubmit {
            focus.wrappedValue = .workflows
          }
          .onChange(of: searchTerm, perform: { value in
            debounce.process(value)
          })
      }
      .opacity(publisher.data.isEmpty ? 0 : 1)

      Button(action: {
        searchTerm = ""
        onClear()
      }, label: { Text("Clear") })
        .environment(\.buttonBackgroundColor, .systemGray)
        .font(.caption2)
        .opacity(!searchTerm.isEmpty ? 1 : 0)
        .frame(width: searchTerm.isEmpty ? 0 : nil, height: 25)
        .animation(.linear, value: searchTerm.isEmpty)
    }
  }
}

struct ContentListFilterView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  @Namespace static var namespace
  static var previews: some View {
    WorkflowsFilterView($focus, namespace: namespace, onClear: {}, onChange: { _ in })
      .designTime()
  }
}
