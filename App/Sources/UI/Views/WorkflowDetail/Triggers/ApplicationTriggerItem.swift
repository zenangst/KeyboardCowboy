import Bonzai
import Inject
import SwiftUI

struct ApplicationTriggerItem: View {
  @EnvironmentObject private var updater: ConfigurationUpdater
  @EnvironmentObject private var transaction: UpdateTransaction
  @ObserveInjection var inject
  @Binding var element: DetailViewModel.ApplicationTrigger
  @Binding private var data: [DetailViewModel.ApplicationTrigger]
  @State var isTargeted: Bool = false
  private let selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>

  init(_ element: Binding<DetailViewModel.ApplicationTrigger>,
       data: Binding<[DetailViewModel.ApplicationTrigger]>,
       selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>) {
    _element = element
    _data = data
    self.selectionManager = selectionManager
  }

  var body: some View {
    HStack(spacing: 12) {
      IconView(icon: element.icon, size: .init(width: 24, height: 24))
      VStack(alignment: .leading, spacing: 4) {
        Text(element.name)
          .frame(maxWidth: .infinity, alignment: .leading)
        HStack {
          ForEach(DetailViewModel.ApplicationTrigger.Context.allCases) { context in
            Toggle(isOn: Binding<Bool>(get: {
              element.contexts.contains(context)
            }, set: { newValue in
              if newValue {
                element.contexts.append(context)
              } else {
                element.contexts.removeAll(where: { $0 == context })
              }
            }), label: {
              Text(context.displayValue)
            })
              .lineLimit(1)
              .allowsTightening(true)
              .truncationMode(.tail)
          }
          .checkboxStyle { checkbox in
            checkbox.style = .small
            checkbox.font = .caption
          }
        }
      }
      ZenDivider(.vertical)
      Button(
        action: {
          withAnimation(CommandList.animation) {
            if let index = data.firstIndex(of: element) {
              data.remove(at: index)
            }
          }
        },
        label: {
          Image(systemName: "xmark")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 8, height: 8)
        })
      .buttonStyle(.destructive)
    }
    .contentShape(Rectangle())
    .roundedStyle(6)
    .overlay(BorderedOverlayView(.readonly { selectionManager.selections.contains(element.id) }, cornerRadius: 6))
    .draggable(element)
    .enableInjection()
  }
}
