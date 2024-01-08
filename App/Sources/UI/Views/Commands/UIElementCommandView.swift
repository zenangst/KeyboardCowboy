import Bonzai
import SwiftUI

struct UIElementCommandView: View {
  enum Action {
    case updateCommand(UIElementCommand)
    case commandAction(CommandContainerAction)
  }
  @State var metaData: CommandViewModel.MetaData
  @State var model: UIElementCommand
  private let debounce: DebounceManager<UIElementCommand>
  private let onAction: (Action) -> Void

  init(metaData: CommandViewModel.MetaData, model: UIElementCommand, onAction: @escaping (Action) -> Void) {
    self.metaData = metaData
    self.model = model
    self.debounce = DebounceManager(for: .milliseconds(500)) { newCommand in
      onAction(.updateCommand(newCommand))
    }
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData) { _ in } content: { _ in
      VStack(alignment: .leading, spacing: 8) {
        ForEach(model.predicates.indices, id: \.self) { index in
          Grid {
            GridRow {
              Text("Value:")
              HStack {
                Menu {
                  ForEach(UIElementCommand.Predicate.Compare.allCases, id: \.displayName) { compare in
                    Button(action: { model.predicates[index].compare = compare },
                           label: {
                      Text(compare.displayName)
                        .font(.callout)
                    })
                  }
                } label: {
                  Text(model.predicates[index].compare.displayName)
                    .font(.caption)
                }
                .fixedSize()
                .menuStyle(.regular)

                TextField("", text: $model.predicates[index].value)
                  .textFieldStyle(.regular(Color(.windowBackgroundColor)))
              }
            }
            GridRow {
              Text("Type:")
              HStack {
                Menu {
                  ForEach(UIElementCommand.Kind.allCases, id: \.displayName) { kind in
                    Button(action: { model.predicates[index].kind = kind },
                           label: {
                      Text(kind.displayName)
                        .font(.callout)
                    })
                  }
                } label: {
                  Text(model.predicates[index].kind.displayName)
                    .font(.caption)
                }
                .menuStyle(.regular)

                ForEach(UIElementCommand.Predicate.Properties.allCases) { property in
                  HStack {
                    ZenCheckbox(
                      isOn: Binding<Bool>(
                        get: { model.predicates[index].properties.contains(property) },
                        set: {
                          if $0 {
                            model.predicates[index].properties.append(property)
                          } else {
                            model.predicates[index].properties.removeAll(where: { $0 == property })
                          }
                        }
                      )
                    )
                    Text(property.displayName)
                      .font(.caption)
                      .lineLimit(1)
                      .truncationMode(.tail)
                      .allowsTightening(true)
                  }
                }

                Button { } label: {
                  Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 8, height: 8)
                }
                .buttonStyle(.calm(color: .systemRed, padding: .medium))
              }
            }
          }
        }
      }
    } subContent: { _ in
    } onAction: { action in
      onAction(.commandAction(action))
    }
    .onChange(of: model, perform: { value in
      debounce.send(value)
    })
    .frame(maxHeight: 180)
  }
}

#Preview {
  UIElementCommandView(
    metaData: .init(name: "Some UI Element", namePlaceholder: ""),
    model: .init(
      predicates: [
        .init(
          value: "issues",
          properties: [.identifier]
        )
      ]
    )
  ) { _ in

  }
  .designTime()
  .previewLayout(.sizeThatFits)
}
