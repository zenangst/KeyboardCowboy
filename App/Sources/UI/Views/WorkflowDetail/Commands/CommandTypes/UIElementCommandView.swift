import Bonzai
import Inject
import SwiftUI

struct UIElementCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @State var model: UIElementCommand
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  private let menuStyle = ZenStyleConfiguration(color: .systemGray,
                                                padding: .init(horizontal: .small, vertical: .small))

  init(metaData: CommandViewModel.MetaData, model: UIElementCommand, iconSize: CGSize) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(metaData, placeholder: model.placeholder) { _ in
      UIElementIconView(size: iconSize.width)
    } content: { _ in
      VStack(alignment: .leading, spacing: 4) {
        ForEach(model.predicates.indices, id: \.self) { index in
          Grid(verticalSpacing: 8) {
            GridRow {
              Text("Value:")
                .font(.caption)
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
                .menuStyle(.zen(menuStyle))

                HStack {
                  TextField("", text: $model.predicates[index].value)
                    .textFieldStyle(
                      .zen(
                        .init(
                          backgroundColor: Color(.windowBackgroundColor),
                          font: .caption,
                          padding: .small
                        )
                      )
                    )
                  Button { 
                    model.predicates.remove(at: index)
                    if model.predicates.isEmpty {
                      updater.modifyWorkflow(using: transaction) { workflow in
                        workflow.commands.removeAll(where: { $0.id == metaData.id })
                      }
                    }
                  } label: {
                    Image(systemName: "xmark")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(width: 8, height: 8)
                  }
                  .buttonStyle(.calm(color: .systemRed, padding: .medium))
                }
              }
            }
            GridRow {
              Text("Type:")
                .font(.caption)
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
                .menuStyle(.zen(menuStyle))

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
                  .help(property.displayName)
                }
              }
            }
          }

          if index < model.predicates.count - 1 {
            ZenDivider()
          }
        }
      }
      .roundedContainer(4, padding: 8, margin: 0)
    } subContent: {
      Menu {
        Button(action: {
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            command.notification = .none
          }
        }, label: { Text("None") })
        ForEach(Command.Notification.regularCases) { notification in
          Button(action: {
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              command.notification = notification
            }
          }, label: { Text(notification.displayValue) })
        }
      } label: {
        switch metaData.notification {
        case .bezel:        Text("Bezel").font(.caption)
        case .capsule:      Text("Capsule").font(.caption)
        case .commandPanel: Text("Command Panel").font(.caption)
        case .none:         Text("None").font(.caption)
        }
      }
      .menuStyle(.zen(.init(color: .systemGray, padding: .medium)))
      .fixedSize()
    }
    .onChange(of: model, perform: { value in
      updater.modifyCommand(withID: metaData.id, using: transaction) { command in
        command = .uiElement(value)
      }
    })
    .enableInjection()
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
    ), iconSize: .init(width: 24, height: 24))
  .designTime()
  .previewLayout(.sizeThatFits)
}
