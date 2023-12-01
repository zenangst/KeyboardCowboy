import Bonzai
import Inject
import SwiftUI

struct EditWorfklowGroupView: View {
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
  @ObservedObject var applicationStore: ApplicationStore
  @EnvironmentObject var publisher: ConfigurationPublisher
  @State var editIcon: WorkflowGroup?
  @State var group: WorkflowGroup
  var action: (Action) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        WorkflowGroupIconView(group: $group, size: 36)
          .contentShape(Circle())
          .onTapGesture {
            editIcon = group
          }
          .popover(item: $editIcon, arrowEdge: .bottom, content: { _ in
            EditGroupIconView(group: $group)
          })
          .overlay(ZStack {
            if let first = group.rule?.bundleIdentifiers.first,
               let app = applicationStore.application(for: first) {
              IconView(icon: Icon(app), size: .init(width: 32, height: 32))
                .allowsHitTesting(false)
            }
          })
          .cornerRadius(24, antialiased: true)
        TextField("Name:", text: $group.name)
          .textFieldStyle(.large(color: .accentColor, backgroundColor: Color(.windowBackgroundColor),
                                 glow: true))
          .prefersDefaultFocus(in: namespace)
          .focused($focus, equals: .name)
      }
      .padding()
      .onAppear {
        focus = .name
      }

      Divider()

      HStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 0) {
          Label.init("User Modes", image: "")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.windowBackgroundColor))
            .labelStyle(HeaderLabelStyle())
          
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
          .padding(.horizontal)
          .padding(.bottom)
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
            .padding()
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
        .buttonStyle(.destructive)
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
