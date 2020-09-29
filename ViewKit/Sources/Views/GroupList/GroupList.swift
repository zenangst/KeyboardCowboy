import SwiftUI

public struct GroupList: View {
  public typealias Controller = AnyViewController<[GroupViewModel], Action>
  public enum Action {
    case newGroup
    case dropFile(URL)
  }

  static let idealWidth: CGFloat = 300

  @EnvironmentObject var userSelection: UserSelection
  @ObservedObject var controller: Controller

  var groups: [GroupViewModel] { controller.state }

  public init(controller: Controller) {
    self.controller = controller
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Groups")
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 0))
        .font(.subheadline)
        .foregroundColor(Color.secondary)
      list
        .onAppear {
          if userSelection.group == nil {
            userSelection.group = groups.first
          }
        }
        .onDrop(of: ["public.file-url"], isTargeted: nil, perform: { providers -> Bool in
          providers.forEach {
            _ = $0.loadObject(ofClass: URL.self) { url, _ in
              guard let url = url else { return }
              controller.action(.dropFile(url))()
            }
          }
          return true
        })
        .listStyle(SidebarListStyle())

      Button("+ Add Group", action: {
        controller.perform(.newGroup)
      })
      .buttonStyle(PlainButtonStyle())
      .padding(.init(top: 0, leading: 8, bottom: 8, trailing: 0))
    }
  }
}

// MARK: - Subviews

private extension GroupList {
  var list: some View {
    List(selection: $userSelection.group) {
      ForEach(groups) { group in
        GroupListCell(group: group)
          .tag(group)
          .onTapGesture(count: 1, perform: {
            userSelection.group = group
          })
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

// MARK: - Previews

struct GroupList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    GroupList(controller: PreviewController().erase())
      .frame(width: GroupList.idealWidth, height: 480)
      .environmentObject(UserSelection())
  }
}

private final class PreviewController: ViewController {
  let state = ModelFactory().groupList()
  func perform(_ action: GroupList.Action) {}
}
