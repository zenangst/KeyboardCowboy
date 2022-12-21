import Foundation
import SwiftUI

struct ContentView: View {
  enum Action {
    case selectWorkflow([ContentViewModel])
    case removeWorflows([ContentViewModel.ID])
    case moveWorkflows(source: IndexSet, destination: Int)
    case addWorkflow
  }
  @ObserveInjection var inject
  @EnvironmentObject private var publisher: ContentPublisher

  @State var selected = Set<ContentViewModel>()

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    List(selection: $publisher.selections) {
      ForEach(publisher.models) { workflow in
        HStack {
          ZStack {
            Rectangle()
              .fill(Color(nsColor: .controlAccentColor).opacity(0.375))
            ContentImagesView(images: workflow.images)
          }
          .overlay(alignment: .topTrailing, content: {
            ZStack {
              Circle()
                .fill(Color(nsColor: .controlAccentColor))
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

          shortcutView(workflow)
        }
        .contextMenu(menuItems: {
          contextualMenu()
        })
        .tag(workflow)
        .id(workflow.id)
      }
      .onMove { source, destination in
        onAction(.moveWorkflows(source: source, destination: destination))
      }
    }
    .onChange(of: publisher.selections, perform: { newValue in
      selected = newValue
      onAction(.selectWorkflow(Array(newValue)))
    })
    .enableInjection()
  }

  @ViewBuilder
  private func shortcutView(_ workflow: ContentViewModel) -> some View {
    if let binding = workflow.binding {
      KeyboardShortcutView(shortcut: .init(key: binding, lhs: true))
        .font(.caption)
        .layoutPriority(-1)
    }
  }

  @ViewBuilder
  private func contextualMenu() -> some View {
    Button("Delete", action: {
      onAction(.removeWorflows(publisher.selections.map { $0.id }))
    })
  }
}

struct ContentImagesView: View {
  @ObserveInjection var inject
  let images: [ContentViewModel.ImageModel]

  var body: some View {
    ForEach(images) { image in
      ContentImageView(image: image)
    }
    .enableInjection()
  }
}

struct ContentImageView: View {
  let image: ContentViewModel.ImageModel

  var body: some View {
    switch image.kind {
    case .nsImage(let nsImage):
      Image(nsImage: nsImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .rotationEffect(.degrees(-(3.75 * image.offset)))
        .offset(.init(width: -(image.offset * 1.25),
                      height: image.offset * 1.25))
    case .command(let kind):
      switch kind {
      case .keyboard(let key, let modifiers):
        ZStack {
          RegularKeyIcon(letter: key)
            .scaleEffect(0.8)

          ForEach(modifiers) { modifier in
            HStack {
              ModifierKeyIcon(key: modifier)
                .scaleEffect(0.4, anchor: .bottomLeading)
                .opacity(0.8)
            }
            .padding(4)
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
                .init(color: Color(nsColor: NSColor(.accentColor)).opacity(0.2), location: 0.0),
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

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView { _ in }
      .designTime()
      .frame(height: 900)
  }
}
