import SwiftUI

struct SidebarView: View {
  enum Action {
    case openScene(AppScene)
    case addConfiguration(name: String)
    case selectConfiguration(ConfigurationViewModel.ID)
    case selectGroups([GroupViewModel.ID])
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups([GroupViewModel.ID])
  }

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    ScrollViewReader { proxy in
      VStack(alignment: .leading, spacing: 0) {
        VStack(alignment: .leading) {
          Label("Configuration", image: "")
          SidebarConfigurationView { action in
            switch action {
            case .addConfiguration(let name):
              onAction(.addConfiguration(name: name))
            case .selectConfiguration(let id):
              onAction(.selectConfiguration(id))
            }
          }
        }
        .padding(.horizontal, 12)
        .padding(.top)


        Label("Groups", image: "")
          .padding(.horizontal, 12)
          .padding(.top)
          .padding(.bottom, 4)

        GroupsView(proxy: proxy) { action in
          switch action {
          case .selectGroups(let ids):
            onAction(.selectGroups(ids))
          case .moveGroups(let source, let destination):
            onAction(.moveGroups(source: source, destination: destination))
          case .removeGroups(let ids):
            onAction(.removeGroups(ids))
          case .openScene(let scene):
            onAction(.openScene(scene))
          }
        }
      }
    }
    .labelStyle(SidebarLabelStyle())
  }
}

struct SidebarView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarView { _ in }
      .designTime()
  }
}

struct AddButtonView: View {
  @State private var isHovered = false

  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 2) {
        Image(systemName: "plus.circle")
          .padding(2)
          .background(
            ZStack {
              RoundedRectangle(cornerRadius: 16)
                .fill(
                  LinearGradient(stops: [
                    .init(color: Color(.systemGreen), location: 0.0),
                    .init(color: Color(.systemGreen.blended(withFraction: 0.5, of: .black)!), location: 1.0),
                  ], startPoint: .top, endPoint: .bottom)
                )
                .opacity(isHovered ? 1.0 : 0.3)
              RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGreen))
                .opacity(isHovered ? 0.4 : 0.1)
            }
          )
          .grayscale(isHovered ? 0 : 1)
          .foregroundColor(
            Color(.labelColor)
          )
            .animation(.easeOut(duration: 0.2), value: isHovered)
        Text("Add Group")
      }
    }
    .buttonStyle(.plain)
    .onHover(perform: { value in
      self.isHovered = value
    })
  }
}
