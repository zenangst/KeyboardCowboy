import SwiftUI

struct SidebarView: View {
  enum Confirm {
    case single(id: GroupViewModel.ID)
    case multiple(ids: [GroupViewModel.ID])

    func contains(_ id: GroupViewModel.ID) -> Bool {
      switch self {
      case .single(let groupId):
        return groupId == id
      case .multiple(let ids):
        return ids.contains(id) && ids.first == id
      }
    }
  }

  enum Action {
    case openScene(AppScene)
    case selectConfiguration(ConfigurationViewModel.ID)
    case selectGroups([GroupViewModel.ID])
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups([GroupViewModel.ID])
  }

  @EnvironmentObject private var groupIds: GroupIdsPublisher
  @EnvironmentObject private var groupStore: GroupStore
  @EnvironmentObject private var groupsPublisher: GroupsPublisher

  @State private var confirmDelete: Confirm?

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

        List(selection: $groupsPublisher.selections) {
          ForEach(groupsPublisher.models) { group in
            SidebarItemView(group, onAction: onAction)
              .contextMenu(menuItems: {
                contextualMenu(for: group, onAction: onAction)
              })
              .overlay(content: {
                HStack {
                  Button(action: { confirmDelete = nil },
                         label: { Image(systemName: "x.circle") })
                  .buttonStyle(.gradientStyle(config: .init(nsColor: .brown)))
                  .keyboardShortcut(.escape)
                  Text("Are you sure?")
                    .font(.footnote)
                  Spacer()
                  Button(action: {
                    confirmDelete = nil
                    onAction(.removeGroups(Array(groupsPublisher.selections)))
                  }, label: { Image(systemName: "trash") })
                  .buttonStyle(.destructiveStyle)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(4)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
                .opacity(confirmDelete?.contains(group.id) == true ? 1 : 0)
              })
              .tag(group)
          }
          .onMove { source, destination in
            onAction(.moveGroups(source: source, destination: destination))
          }
        }
        .onDeleteCommand(perform: {
          if groupsPublisher.models.count > 1 {
            confirmDelete = .multiple(ids: Array(groupsPublisher.selections))
          } else if let first = groupsPublisher.models.first {
            confirmDelete = .single(id: first.id)
          }
        })
        .onChange(of: groupsPublisher.selections) { newValue in
          confirmDelete = nil
          groupIds.publish(.init(ids: Array(newValue)))
          onAction(.selectGroups(Array(newValue)))

          if let first = newValue.first {
            proxy.scrollTo(first, anchor: .center)
          }
        }

        AddButtonView {
          onAction(.openScene(.addGroup))
        }
        .padding(8)
        .overlay(alignment: .top, content: { overlayView() })
      }
    }
    .labelStyle(SidebarLabelStyle())
  }

  private func overlayView() -> some View {
    VStack(spacing: 0) {
      LinearGradient(stops: [
        Gradient.Stop.init(color: .clear, location: 0),
        Gradient.Stop.init(color: .black.opacity(0.25), location: 0.25),
        Gradient.Stop.init(color: .black.opacity(0.75), location: 0.5),
        Gradient.Stop.init(color: .black.opacity(0.25), location: 0.75),
        Gradient.Stop.init(color: .clear, location: 1),
      ],
                     startPoint: .leading,
                     endPoint: .trailing)
      .frame(height: 1)
    }
      .allowsHitTesting(false)
      .shadow(color: Color(.black).opacity(0.25), radius: 2, x: 0, y: -2)
  }

  @ViewBuilder
  private func contextualMenu(for group: GroupViewModel,
                              onAction: @escaping (SidebarView.Action) -> Void) -> some View {
    Button("Edit", action: { onAction(.openScene(.editGroup(group.id))) })
    Divider()
    Button("Remove", action: {
      onAction(.removeGroups([group.id]))
    })
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
          .font(.caption)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .buttonStyle(.plain)
    .onHover(perform: { value in
      self.isHovered = value
    })
  }
}
