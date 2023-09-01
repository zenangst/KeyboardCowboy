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
      .menuStyle(GradientMenuStyle(.init(nsColor: .systemGray, grayscaleEffect: true),
                                   fixedSize: false))

      Menu(content: {
        Button("New Configuration", action: {
          configurationName = ""
          newConfigurationPopover = true
        })
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
      .popover(isPresented: $deleteConfigurationPopover,
               arrowEdge: .bottom,
               content: {
        SidebarDeleteConfigurationPopoverView($deleteConfigurationPopover,
                                              id: selectionManager.selections.first ?? "",
                                              configurationName: publisher.data.first(where: { $0.selected })?.name ?? "",
                                              selectionManager: selectionManager,
                                              onAction: { onAction(.deleteConfiguration(id: $0)) })
      })
      .popover(isPresented: $updateConfigurationNamePopover,
               arrowEdge: .bottom,
               content: {
        SidebarUpdateConfigurationNamePopoverView($updateConfigurationNamePopover, configurationName: $configurationName, onAction: {
          onAction(.updateName(name: $0))
        })
      })
      .popover(isPresented: $newConfigurationPopover, arrowEdge: .bottom) {
        SidebarNewConfigurationPopoverView($newConfigurationPopover, configurationName: "", onAction: {
          onAction(.addConfiguration(name: $0))
        })
      }
    }
    .padding(.top, 4)
  }
}

struct SidebarConfigurationView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarConfigurationView(.init()) { _ in }
      .designTime()
  }
}
