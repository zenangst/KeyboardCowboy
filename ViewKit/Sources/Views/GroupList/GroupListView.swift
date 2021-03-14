import SwiftUI
import ModelKit

struct GroupListViewConfig {
  var name: String
  var hexColor: String
  var symbol: String
  var count: Int
}

struct GroupListView: View {
  typealias EditAction = (GroupListViewConfig) -> Void

  @State private var config: GroupListViewConfig
  @State private var isHovering: Bool = false
  private var bundleIdentifier: String?
  let editAction: EditAction

  init(_ group: ModelKit.Group, editAction: @escaping EditAction) {
    _config = .init(wrappedValue: GroupListViewConfig(name: group.name,
                                                      hexColor: group.color,
                                                      symbol: group.symbol,
                                                      count: group.workflows.count))
    self.editAction = editAction

    if let bundleIdentifier = group.rule?.bundleIdentifiers.first {
      self.bundleIdentifier = bundleIdentifier
    }
  }

  var body: some View {
    HStack {
      icon
      text
      Spacer()
      if isHovering {
        editButton { editAction(config) }
      }
      numberOfWorkflows
    }
    .onHover(perform: { hovering in
      isHovering = hovering
    })
    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
    .frame(minHeight: 36)
  }
}

// MARK: - Subviews

private extension GroupListView {
  var icon: some View {
    ZStack {
    Circle()
      .fill(Color(hex: config.hexColor))
      .frame(width: 24, height: 24, alignment: .center)
      .overlay(overlay)
      .shadow(radius: 2)
    }
  }

  var overlay: AnyView {
    if let bundleIdentifier = bundleIdentifier,
       let applicationIcon = IconController.shared.createIconView(bundleIdentifier) {
      return AnyView(
        applicationIcon.frame(width: 18, height: 18, alignment: .center)
          .accentColor(.gray)
      )
    } else {
      return AnyView(Image(systemName: config.symbol)
        .renderingMode(.template)
        .foregroundColor(.white))
    }
  }

  var text: some View {
    Text(config.name)
      .foregroundColor(.primary)
      .lineSpacing(-2.0)
  }

  func editButton(_ action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: "ellipsis.circle")
        .foregroundColor(Color(.secondaryLabelColor))
    }
    .buttonStyle(PlainButtonStyle())
  }

  var numberOfWorkflows: some View {
    Text("\(config.count)")
      .foregroundColor(.secondary)
      .padding(.vertical, 2)
  }
}

// MARK: - Previews

struct GroupListCell_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let group = ModelFactory().groupListCell()
    return GroupListView(group, editAction: { _ in })
      .frame(width: 300)
  }
}
