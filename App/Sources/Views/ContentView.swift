import Foundation
import SwiftUI

struct ContentView: View {
  enum Action: Hashable {
    case selectWorkflow(models: [ContentViewModel.ID], inGroups: [WorkflowGroup.ID])
    case removeWorflows([ContentViewModel.ID])
    case moveWorkflows(source: IndexSet, destination: Int)
    case addWorkflow(workflowId: Workflow.ID)
  }

  @EnvironmentObject private var publisher: ContentPublisher
  @EnvironmentObject private var groupIds: GroupIdsPublisher

  @State var selected = Set<ContentViewModel.ID>()
  @State var overlayOpacity: CGFloat = 0

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    ScrollViewReader { proxy in
      List(selection: $publisher.selections) {
        ForEach(publisher.models) { workflow in
          ContentItemView(workflow: workflow)
            .onFrameChange(perform: { rect in
              if workflow == publisher.models.first {
                let value = min(max(1.0 - rect.origin.y / 52.0, 0.0), 0.9)
                overlayOpacity = value
              }
            })
            .grayscale(workflow.isEnabled ? 0 : 0.5)
            .opacity(workflow.isEnabled ? 1 : 0.5)
            .contextMenu(menuItems: {
              contextualMenu()
            })
            .tag(workflow.id)
            .id(workflow.id)
        }
        .onMove { source, destination in
          onAction(.moveWorkflows(source: source, destination: destination))
        }
      }
      .onDeleteCommand(perform: {
        guard !publisher.selections.isEmpty else { return }
        onAction(.removeWorflows(Array(publisher.selections)))
      })
      .onChange(of: publisher.selections, perform: { newValue in
        selected = newValue
        onAction(.selectWorkflow(models: Array(newValue), inGroups: groupIds.model.ids))
        if let first = newValue.first {
          proxy.scrollTo(first, anchor: .center)
        }
      })
      .overlay(alignment: .top, content: { overlayView() })
      .toolbar {
        ToolbarItemGroup(placement: .navigation) {
          Button(action: {
            onAction(.addWorkflow(workflowId: UUID().uuidString))
          },
                 label: {
            Label(title: {
              Text("Add workflow")
            }, icon: {
              Image(systemName: "rectangle.stack.badge.plus")
                .renderingMode(.template)
                .foregroundColor(Color(.systemGray))
            })
          })
        }
      }
    }
  }

  private func overlayView() -> some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(Color(.gridColor))
        .frame(height: 36)
      Rectangle()
        .fill(Color.gray)
        .frame(height: 1)
        .opacity(0.25)
      Rectangle()
        .fill(Color.black)
        .frame(height: 1)
        .opacity(0.5)
    }
      .opacity(overlayOpacity)
      .allowsHitTesting(false)
      .shadow(color: Color(.gridColor), radius: 8, x: 0, y: 2)
      .edgesIgnoringSafeArea(.top)
  }

  private func contextualMenu() -> some View {
    Button("Delete", action: {
      onAction(.removeWorflows(publisher.selections.map { $0 }))
    })
  }
}

struct ContentItemView: View {
  let workflow: ContentViewModel

  var body: some View {
    HStack {
      ZStack {
        Rectangle()
          .fill(Color.accentColor.opacity(0.375))
        ContentImagesView(images: workflow.images)
      }
      .overlay(alignment: .topTrailing, content: {
        ZStack {
          Circle()
            .fill(Color.accentColor)
          Text("\(workflow.badge)")
            .bold()
            .font(.caption2)
        }
        .frame(width: 12)
        .offset(x: -2, y: 2)
        .aspectRatio(contentMode: .fit)
        .shadow(color: .black.opacity(0.75), radius: 2)
        .opacity(workflow.badgeOpacity)
      })
      .frame(width: 32, height: 32)
      .cornerRadius(8, antialiased: false)

      Text(workflow.name)
        .lineLimit(1)
        .allowsTightening(true)
      Spacer()

      if let binding = workflow.binding {
        KeyboardShortcutView(shortcut: .init(key: binding, lhs: true))
          .font(.caption)
          .layoutPriority(-1)
      }
    }
  }
}

struct ContentImagesView: View {
  let images: [ContentViewModel.ImageModel]

  var body: some View {
    ForEach(images) { image in
      ContentImageView(image: image)
    }
  }
}

struct ContentImageView: View {
  let image: ContentViewModel.ImageModel

  var body: some View {
    switch image.kind {
    case .icon(let path):
      Group {
        if path.hasSuffix("icns") {
          Image(nsImage: NSImage(byReferencing: URL(filePath: path)))
            .resizable()
        } else {
          Image(nsImage: NSWorkspace.shared.icon(forFile: path))
            .resizable()
        }
      }
        .aspectRatio(contentMode: .fit)
        .rotationEffect(.degrees(-(3.75 * image.offset)))
        .offset(.init(width: -(image.offset * 1.25),
                      height: image.offset * 1.25))
    case .command(let kind):
      switch kind {
      case .keyboard(let keys):
        ZStack {
          ForEach(keys) { key in
            RegularKeyIcon(letter: key.key)
              .scaleEffect(0.8)

            ForEach(key.modifiers) { modifier in
              HStack {
                ModifierKeyIcon(key: modifier)
                  .scaleEffect(0.4, anchor: .bottomLeading)
                  .opacity(0.8)
              }
              .padding(4)
            }
          }
        }
        .rotationEffect(.degrees(-(3.75 * image.offset)))
        .offset(.init(width: -(image.offset * 1.25),
                      height: image.offset * 1.25))
      case .application:
       EmptyView()
      case .open:
        EmptyView()
      case .script(let scriptKind):
        switch scriptKind {
        case .inline:
          ZStack {
            Rectangle()
              .fill(LinearGradient(stops: [
                .init(color: Color.accentColor.opacity(0.2), location: 0.0),
                .init(color: .black, location: 0.2),
                .init(color: .black, location: 1.0),
              ], startPoint: .top, endPoint: .bottom))
              .cornerRadius(8)
              .scaleEffect(0.9)
            RoundedRectangle(cornerRadius: 8)
              .stroke(.black)
              .scaleEffect(0.9)

            Text(">_")
              .font(Font.system(.caption, design: .monospaced))
          }
        case .path:
          Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Script Editor.app"))
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 32)
        }
      case .shortcut:
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
          .resizable()
          .aspectRatio(1, contentMode: .fill)
          .frame(width: 32)
      case .type:
        RegularKeyIcon(letter: "(...)", width: 25, height: 25)
          .frame(width: 24, height: 24)
      case .plain:
        EmptyView()
      }
    }
  }
}

struct GeometryPreferenceKeyView<Key: PreferenceKey>: ViewModifier {
    typealias Transform = (GeometryProxy) -> Key.Value
    private let space: CoordinateSpace
    private let transform: Transform

    init(space: CoordinateSpace, transform: @escaping Transform) {
        self.space = space
        self.transform = transform
    }

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { Color.clear.preference(key: Key.self, value: transform($0)) })
    }
}

struct FramePreferenceKey: PreferenceKey {
    typealias Value = CGRect
    static var defaultValue = CGRect.zero

    static func reduce(value: inout Value, nextValue: () -> Value) { }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView { _ in }
      .designTime()
      .frame(height: 900)
  }
}

extension View {
  func onFrameChange(space: CoordinateSpace = .global, perform: @escaping (CGRect) -> Void) -> some View {
      self
          .modifier(GeometryPreferenceKeyView<FramePreferenceKey>(space: space, transform: { $0.frame(in: space) }))
          .onPreferenceChange(FramePreferenceKey.self, perform: perform)
  }
}
