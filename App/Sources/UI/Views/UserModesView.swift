import Bonzai
import Inject
import SwiftUI

struct UserModesView: View {
  enum Action {
    case add(UserMode.ID)
    case delete(UserMode.ID)
    case rename(UserMode.ID, String)
  }
  @ObserveInjection var inject
  @EnvironmentObject var publisher: ConfigurationPublisher
  @State private var isAddingNew = false
  let onAction: (Action) -> Void

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Label("User Modes", image: "")
        Spacer()
        Button(action: { isAddingNew = true }, label: {
          Image(systemName: "plus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 8)
        })
        .buttonStyle(.zen(.init(calm: true, color: .systemGreen, grayscaleEffect: .constant(true))))
        .popover(isPresented: $isAddingNew, arrowEdge: .bottom, content: {
          AddUserModeView(action: { newName in
            isAddingNew = false
            onAction(.add(newName))
          })
          .padding()
        })
      }

      FlowLayout {
        ForEach(publisher.data.userModes) { userMode in
          FlowItem(userMode: userMode, onAction: { }, onDelete: {
            onAction(.delete(userMode.id))
          }, onRename: {
            onAction(.rename(userMode.id, $0))
          })
          .transition(.fadeAndGrow.animation(.smooth))
        }
      }
    }
    .enableInjection()
  }
}

struct FlowItem: View {
  @ObserveInjection var inject
  @State var isHovered: Bool = false
  @State var areYouSure: Bool = false
  @State var rename: Bool = false
  @State var userMode: UserMode

  let onAction: () -> Void
  let onDelete: () -> Void
  let onRename: (String) -> Void

  init(
    userMode: UserMode,
    onAction: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onRename: @escaping (String) -> Void
  ) {
    self.userMode = userMode
    self.onAction = onAction
    self.onDelete = onDelete
    self.onRename = onRename
  }

  var body: some View {
    Button(action: { rename = true }, label: {
      Text(userMode.name)
        .font(.caption2)
    })
    .overlay(alignment: .topTrailing, content: {
      Button(action: {
        areYouSure = true
      }, label: {
        Image(systemName: "xmark.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 12)
      })
      .buttonStyle(.borderless)
      .offset(x: 4, y: -4)
      .scaleEffect(isHovered ? 1 : 0.5)
      .opacity(isHovered ? 1 : 0)
      .animation(.smooth, value: isHovered)
    })
    .buttonStyle(.zen(.init()))
    .onHover(perform: { hovering in
      isHovered = hovering
    })
    .contextMenu(ContextMenu(menuItems: {
      Button(action: {
        areYouSure = true
      }, label: {
        Text("Delete")
      })
    }))
    .popover(isPresented: $rename, content: {
      HStack {
        TextField("", text: $userMode.name)
          .onSubmit {
            rename = false
          }
      }
      .padding(6)
      .buttonStyle(.regular)
      .font(.caption)
      .onDisappear {
        onRename(userMode.name)
      }
    })
    .popover(isPresented: $areYouSure, content: {
      HStack {
        Text("Are you sure?")
          .padding(.leading, 6)
        Spacer()
        Button(action: { areYouSure = false }, label: {
          Text("Cancel")
        })
        Button(action: { 
          areYouSure = true
          onDelete()
        }, label: {
          Text("Delete")
        })
        .buttonStyle(.destructive)
      }
      .padding(6)
      .buttonStyle(.regular)
      .font(.caption)
    })
    .enableInjection()
  }
}

#Preview {
  UserModesView(onAction: { _ in })
}
