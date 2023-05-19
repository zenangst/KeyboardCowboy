import SwiftUI

struct WorkflowApplicationTriggerItemView: View {
  @Binding var element: DetailViewModel.ApplicationTrigger
  @Binding private var data: [DetailViewModel.ApplicationTrigger]
  @State var isTargeted: Bool = false
  private let focusPublisher: FocusPublisher<DetailViewModel.ApplicationTrigger>
  private let selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let onAction: (WorkflowApplicationTriggerView.Action) -> Void

  init(_ element: Binding<DetailViewModel.ApplicationTrigger>,
       data: Binding<[DetailViewModel.ApplicationTrigger]>,
       focusPublisher: FocusPublisher<DetailViewModel.ApplicationTrigger>,
       selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       onAction: @escaping (WorkflowApplicationTriggerView.Action) -> Void) {
    _element = element
    _data = data
    self.focusPublisher = focusPublisher
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    HStack(spacing: 0) {
      IconView(icon: element.icon, size: .init(width: 36, height: 36))
      VStack(alignment: .leading, spacing: 4) {
        Text(element.name)
        HStack {
          ForEach(DetailViewModel.ApplicationTrigger.Context.allCases) { context in
            Toggle(context.displayValue, isOn: Binding<Bool>(get: {
              element.contexts.contains(context)
            }, set: { newValue in
              if newValue {
                element.contexts.append(context)
              } else {
                element.contexts.removeAll(where: { $0 == context })
              }

              onAction(.updateApplicationTriggerContext(element))
            }))
            .font(.caption)
          }
        }
      }
      .padding(8)
      Spacer()
      Divider()
        .opacity(0.25)
      Button(
        action: {
          withAnimation(WorkflowCommandListView.animation) {
            if let index = data.firstIndex(of: element) {
              data.remove(at: index)
            }
          }
          onAction(.updateApplicationTriggers(data))
        },
        label: {
          Image(systemName: "xmark")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 8, height: 8)
        })
      .buttonStyle(.gradientStyle(config: .init(nsColor: .systemRed, grayscaleEffect: true)))
      .padding(.horizontal, 8)
    }
    .padding(.leading, 8)
    .background(Color(.textBackgroundColor).opacity(0.75))
    .cornerRadius(8)
    .compositingGroup()
    .shadow(radius: 2)
    .background(
      FocusView(focusPublisher, element: $element,
                isTargeted: $isTargeted,
                selectionManager: selectionManager,
                cornerRadius: 8, style: .focusRing)
    )
    .draggable(element.draggablePayload(prefix: "WAT|", selections: selectionManager.selections))
    .dropDestination(for: String.self) { items, location in
      guard let payload = items.draggablePayload(prefix: "WAT|"),
            let (from, destination) = data.moveOffsets(for: element,
                                                       with: payload) else {
        return false
      }
      withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
        data.move(fromOffsets: IndexSet(from), toOffset: destination)
      }
      onAction(.updateApplicationTriggers(data))
      return true
    } isTargeted: { newValue in
      isTargeted = newValue
    }
  }
}
