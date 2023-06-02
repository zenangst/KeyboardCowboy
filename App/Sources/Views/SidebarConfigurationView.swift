import SwiftUI

struct SidebarConfigurationView: View {
  enum Action {
    case addConfiguration(name: String)
    case deleteConfiguration(id: ConfigurationViewModel.ID)
    case updateName(name: String)
    case selectConfiguration(ConfigurationViewModel.ID)
  }
  @EnvironmentObject private var publisher: ConfigurationPublisher
  @ObservedObject var selectionManager: SelectionManager<ConfigurationViewModel>
  @State var configurationName: String = ""
  @State var newConfigurationPopover = false
  @State var updateConfigurationNamePopover = false
  @State var deleteConfigurationPopover = false

  private let onAction: (Action) -> Void

  init(_ selectionManager: SelectionManager<ConfigurationViewModel>, onAction: @escaping (Action) -> Void) {
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      HStack {
        Menu {
          ForEach(publisher.data) { configuration in
            Button(action: {
              selectionManager.publish([configuration.id])
              onAction(.selectConfiguration(configuration.id))
            }, label: { Text(configuration.name) })
          }
        } label: {
          Text(publisher.data.first(where: { $0.selected })?.name ?? "Missing value" )
            .font(.callout)
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
            .allowsTightening(true)
            .contentShape(Rectangle())
        }
        .menuStyle(IconMenuStyle())
      }
      .padding(.vertical, 4)
      .padding(.horizontal, 6)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(.disabledControlTextColor))
      )

      Menu(content: {
        Button("New Configuration", action: { newConfigurationPopover = true })
        Button("Rename Configuration", action: {
          configurationName = publisher.data.first(where: { $0.selected })?.name ?? ""
          updateConfigurationNamePopover = true
        })
        Divider()
        Button("Delete Configuration", action: {
          configurationName = publisher.data.first(where: { $0.selected })?.name ?? ""
          deleteConfigurationPopover = true
        })
      }, label: {
        Image(systemName: "ellipsis.circle")
          .resizable()
      })
      .menuStyle(GradientMenuStyle(.init(nsColor: .systemGreen, grayscaleEffect: true)))
      .menuIndicator(.hidden)
      .popover(isPresented: $deleteConfigurationPopover, arrowEdge: .bottom, content: {
        VStack {
          Text("Are you sure you want to delete '\(configurationName)'")
          HStack {
            Button("Abort", action: {
              deleteConfigurationPopover = false
            })
            .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGray, hoverEffect: false)))
            .keyboardShortcut(.cancelAction)
            Button("Confirm", action: {
              onAction(.deleteConfiguration(id: selectionManager.selections.first ?? ""))
              deleteConfigurationPopover = false
            })
            .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, hoverEffect: false)))
          }
        }
        .padding()
      })
      .popover(isPresented: $updateConfigurationNamePopover, arrowEdge: .bottom, content: {
        HStack {
          Text("Configuration name:")
          TextField("", text: $configurationName)
            .frame(width: 170)
            .onSubmit {
              onAction(.updateName(name: configurationName))
              updateConfigurationNamePopover = false
              configurationName = ""
            }
          Button("Save", action: {
            onAction(.updateName(name: configurationName))
            updateConfigurationNamePopover = false
            configurationName = ""
          })
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, hoverEffect: false)))
        }
        .padding()
      })
      .popover(isPresented: $newConfigurationPopover, arrowEdge: .bottom) {
        HStack {
          Text("Configuration name:")
          TextField("", text: $configurationName)
            .frame(width: 170)
            .onSubmit {
              onAction(.addConfiguration(name: configurationName))
              newConfigurationPopover = false
              configurationName = ""
            }
          Button("Save", action: {
            onAction(.addConfiguration(name: configurationName))
            newConfigurationPopover = false
            configurationName = ""
          })
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, hoverEffect: false)))
        }
        .padding()
      }
    }
    .debugEdit()
  }
}

struct SidebarConfigurationView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarConfigurationView(.init()) { _ in }
      .designTime()
  }
}
