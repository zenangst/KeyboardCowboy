import SwiftUI

struct ContentView: View {
  enum Action {
    case selectWorkflow([ContentViewModel])
    case addWorkflow
  }
  @ObserveInjection var inject
  @EnvironmentObject private var publisher: ContentPublisher

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
          .frame(width: 32, height: 32)
          .cornerRadius(8, antialiased: false)
          .clipped()

          Text(workflow.name)
            .lineLimit(1)
            .allowsTightening(true)
          Spacer()

          if let binding = workflow.binding {
            KeyboardShortcutView(shortcut: .init(key: binding, lhs: true))
              .font(.caption)
          }
        }
        .badge(workflow.badge)
        .tag(workflow)
      }
    }
    .onChange(of: publisher.selections, perform: { newValue in
      onAction(.selectWorkflow(Array(newValue)))
    })
    .listStyle(InsetListStyle())
    .enableInjection()
  }
}

struct ContentImagesView: View {
  let images: [ContentViewModel.Image]

  var body: some View {
    ForEach(images) { image in
      Image(nsImage: image.nsImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .rotationEffect(.degrees(-(3.75 * image.offset)))
        .offset(.init(width: -(image.offset * 1.25),
                      height: image.offset * 1.25))
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView { _ in }
      .designTime()
  }
}
