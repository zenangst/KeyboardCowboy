import Bonzai
import Inject
import SwiftUI

struct EditWorfklowGroupView: View {
  enum Context: Identifiable, Hashable, Codable {
    var id: String {
      switch self {
      case .add(let group):
        return group.id
      case .edit(let group):
        return group.id
      }
    }
    case add(WorkflowGroup)
    case edit(WorkflowGroup)
  }
  enum Focus {
    case name
  }
  enum Action {
    case ok(WorkflowGroup)
    case cancel
  }

  @ObserveInjection var inject
  @Namespace var namespace
  @FocusState var focus: Focus?
  let applicationStore: ApplicationStore
  @EnvironmentObject var publisher: ConfigurationPublisher
  @State var editIcon: WorkflowGroup?
  @State var group: WorkflowGroup
  var action: (Action) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        WorkflowGroupIconView(applicationStore: applicationStore, group: $group, size: 36)
          .contentShape(Circle())
          .onTapGesture {
            editIcon = group
          }
          .popover(item: $editIcon, arrowEdge: .bottom, content: { _ in
            EditGroupIconView(group: $group)
              .frame(maxHeight: 300)
          })
          .cornerRadius(24, antialiased: true)
        TextField("Name:", text: $group.name)
          .textFieldStyle(.large(color: .accentColor, backgroundColor: Color(.windowBackgroundColor),
                                 glow: true))
          .prefersDefaultFocus(in: namespace)
          .focused($focus, equals: .name)

        ZenToggle(
          isOn: Binding<Bool>(get: { !group.isDisabled }, set: { group.isDisabled = !$0 })
        )
      }
      .padding()
      .onAppear {
        focus = .name
      }

      Divider()

      HStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            UserModeIconView(size: 24)
            ZenLabel("User Modes")
          }
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.windowBackgroundColor))

          Menu("Add User Mode") {
            ForEach(publisher.data.userModes) { userMode in
              Button(action: {
                guard !group.userModes.contains(userMode) else { return }
                group.userModes.append(userMode)
              }, label: {
                Text(userMode.name)
              })
            }
          }
          .padding([.leading, .trailing, .bottom], 8)
          .menuStyle(.regular)
          
          ScrollView {
            ForEach(group.userModes) { userMode in
              Divider()
              HStack {
                Text(userMode.name)
                Spacer()
                Button(action: {
                  group.userModes.removeAll(where: { $0.id == userMode.id })
                }, label: {
                  Image(systemName: "trash")
                })
                .buttonStyle(.calm(color: .systemRed, padding: .medium))

              }
              .padding(.horizontal)
            }
          }
        }
        .background(Color(.windowBackgroundColor))
        .roundedContainer(padding: 0, margin: 0)
        .padding([.top, .leading, .bottom], 16)

        VStack(alignment: .leading, spacing: 0) {
          RuleHeaderView(applicationStore: applicationStore, group: $group)
            .padding(8)
            .background(Color(.windowBackgroundColor))
          ScrollView {
            RuleListView(applicationStore: applicationStore,
                         group: $group)
            .focusSection()
          }
          .background(Color(.windowBackgroundColor))
          
          VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
              Text("Workflows in this group are only activated when the following applications are the frontmost app.\n") +
              Text("The order of this list is irrelevant. If this list is empty, then the workflows are considered global.")
            }
            .fixedSize(horizontal: false, vertical: true)
            .font(.caption)
          }
          .padding()
        }
        .roundedContainer(padding: 0, margin: 0)
        .padding([.top, .trailing, .bottom], 16)
      }

      HStack {
        Button(role: .cancel) {
          action(.cancel)
        } label: {
          Text("Cancel")
            .frame(minWidth: 40)
        }
        .buttonStyle(.zen(.init(color: .systemGray, hoverEffect: .constant(false))))
        .keyboardShortcut(.cancelAction)

        Spacer()

        Button(action: { action(.ok(group)) }) {
          Text("OK")
            .frame(minWidth: 40)
        }
        .buttonStyle(.zen(.init(color: .systemGreen, hoverEffect: .constant(false))))
        .keyboardShortcut(.defaultAction)
      }
      .padding()
    }
    .focusScope(namespace)
    .frame(minWidth: 600, minHeight: 400)
    .enableInjection()
  }
}

struct EditWorfklowGroupView_Previews: PreviewProvider {
  static let group = WorkflowGroup.designTime()
  static var previews: some View {
    EditWorfklowGroupView(
      applicationStore: ApplicationStore.shared,
      group: group,
      action: { _ in })
    .designTime()
  }
}
