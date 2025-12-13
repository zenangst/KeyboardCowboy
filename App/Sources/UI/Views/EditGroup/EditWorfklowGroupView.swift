import Bonzai
import HotSwiftUI
import SwiftUI

struct EditWorfklowGroupView: View {
  enum Context: Identifiable, Hashable, Codable {
    var id: String {
      switch self {
      case let .add(group):
        group.id
      case let .edit(group):
        group.id
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
        Button(action: { editIcon = group }, label: {
          WorkflowGroupIconView(applicationStore: applicationStore, group: $group, size: 28)
            .contentShape(Circle())
            .popover(item: $editIcon, arrowEdge: .bottom, content: { _ in
              EditGroupIconView(group: $group)
                .frame(maxHeight: 300)
            })
            .cornerRadius(24, antialiased: true)
        })
        .environment(\.buttonCornerRadius, 28)
        .environment(\.buttonPadding, .zero)

        TextField("Name:", text: $group.name)
          .environment(\.textFieldFont, .largeTitle)
          .prefersDefaultFocus(in: namespace)
          .focused($focus, equals: .name)

        Toggle(isOn: Binding<Bool>(get: { !group.isDisabled }, set: { group.isDisabled = !$0 }), label: {})
          .switchStyle()
      }
      .padding(.top, 24)
      .style(.derived)
      .onAppear {
        focus = .name
      }
      .background(alignment: .bottom, content: {
        Background()
          .edgesIgnoringSafeArea(.all)
      })

      ZenDivider()

      HStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 0) {
          HStack(spacing: 0) {
            UserModeIconView(size: 16)
              .style(.derived)
            ZenLabel("User Modes")
              .style(.derived)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .style(.derived)

          ZenDivider()

          Group {
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
            .style(.derived)
            .style(.list)

            ScrollView {
              ForEach(group.userModes) { userMode in
                HStack {
                  Text(userMode.name)
                    .frame(minHeight: 24)
                  Spacer()
                  Button(action: {
                    group.userModes.removeAll(where: { $0.id == userMode.id })
                  }, label: {
                    Image(systemName: "trash")
                  })
                  .buttonStyle(.destructive)
                }
                .style(.item)
                .style(.derived)
                ZenDivider()
              }
            }
          }
        }
        .roundedStyle(padding: 0)

        VStack(alignment: .center, spacing: 0) {
          AllowedApplicationsHeaderView(applicationStore: applicationStore, group: $group)
          ScrollView {
            AllowedApplicationsListView(applicationStore: applicationStore, group: $group)
              .focusSection()
          }

          DisallowedApplicationsHeaderView(applicationStore: applicationStore, group: $group)
          ScrollView {
            DisallowedApplicationsListView(applicationStore: applicationStore, group: $group)
              .focusSection()
          }
        }
        .buttonStyle(.destructive)
        .roundedStyle(padding: 0)
      }
      .style(.list)
      .environment(\.menuFont, .caption)
      .environment(\.menuUnfocusedOpacity, 1.0)

      HStack {
        Button(role: .cancel) {
          action(.cancel)
        } label: {
          Text("Cancel")
            .frame(minWidth: 40)
        }
        .buttonStyle(.cancel)
        .keyboardShortcut(.cancelAction)

        Spacer()

        Button(action: { action(.ok(group)) }) {
          Text("Save")
            .frame(minWidth: 40)
        }
        .environment(\.buttonBackgroundColor, .systemGreen)
        .environment(\.buttonHoverEffect, true)
        .keyboardShortcut(.defaultAction)
      }
      .style(.derived)
      .style(.list)
    }
    .focusScope(namespace)
    .frame(minWidth: 600, minHeight: 400)
    .style(.section(.detail))
    .ignoresSafeArea(.all)
    .enableInjection()
  }
}

private struct Background: View {
  @Environment(\.colorScheme) var colorScheme
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: gradientStops(), startPoint: .top, endPoint: .bottom),
      )
  }

  func gradientStops() -> [Gradient.Stop] {
    colorScheme == .dark
      ?
      [
        .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.3, of: .white)!), location: 0.0),
        .init(color: Color(nsColor: .windowBackgroundColor), location: 0.01),
        .init(color: Color(nsColor: .windowBackgroundColor), location: 1.0),
      ]
      :
      [
        .init(color: Color(nsColor: .systemGray), location: 0.0),
        .init(color: Color(nsColor: .white), location: 0.01),
        .init(color: Color(nsColor: .windowBackgroundColor), location: 1.0),
      ]
  }

  func shadowColor() -> Color {
    colorScheme == .dark
      ? Color(.sRGBLinear, white: 0, opacity: 0.33)
      : Color(.sRGBLinear, white: 0, opacity: 0.15)
  }
}

struct EditWorfklowGroupView_Previews: PreviewProvider {
  static let group = WorkflowGroup.designTime()
  static var previews: some View {
    EditWorfklowGroupView(
      applicationStore: ApplicationStore.shared,
      group: group,
      action: { _ in },
    )
    .designTime()
  }
}
