import Apps
import SwiftUI

struct SearchView: View {
  @ObserveInjection var inject
  let applicationStore: ApplicationStore
  @ObservedObject private var searchStore: SearchStore
  @State var selection = Set<SearchResult>()

  init(applicationStore: ApplicationStore, searchStore: SearchStore) {
    self.applicationStore = applicationStore
    self.searchStore = searchStore
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 10) {
        ForEach(searchStore.results) { result in
          ResponderView(result) { responder in
            HStack(spacing: 8) {
              switch result.kind {
              case .workflow(let workflow):
                icons(workflow.commands)
                  .frame(width: 32, height: 32)
                VStack(alignment: .leading) {
                  Text(workflow.name)
                  Text("Workflow")
                    .font(.caption2)
                }
              case .command(let command):
                commandIcon(command)
                  .frame(width: 32, height: 32)
                VStack(alignment: .leading) {
                  Text(command.name)
                  Text("Command")
                    .font(.caption2)
                }
              }
              Spacer()
            }
            .padding([.top, .bottom], 4)
            .padding([.leading, .trailing], 8)
            .background(ResponderBackgroundView(responder: responder))
          }
        }
      }
      .padding()
    }
    .enableInjection()
  }

  func icons(_ commands: [Command]) -> some View {
    ZStack {
      if commands.count > 3 {
        ForEach(commands[0..<3], content: commandIcon)
      } else {
        ForEach(commands, content: commandIcon)
      }
    }
  }

  @ViewBuilder
  func commandIcon(_ command: Command) -> some View {
    switch command {
    case .application(let applicationCommand):
      IconView(path: applicationCommand.application.path)
    case .builtIn:
      Spacer()
    case .keyboard(let command):
      RegularKeyIcon(letter: command.keyboardShortcut.key,
                     width: 32,
                     height: 32,
                     alignment: .center,
                     glow: .constant(false))
    case .open(let command):
      if let application = command.application {
        IconView(path: application.path)
          .frame(width: 32, height: 32)
      } else if command.isUrl {
        IconView(path: "/Applications/Safari.app")
          .frame(width: 32, height: 32)
      } else {
        IconView(path: command.path)
          .frame(width: 32, height: 32)
      }
    case .script(let command):
      switch command {
      case .appleScript:
        IconView(path: "/System/Applications/Utilities/Script Editor.app")
      case .shell:
        IconView(path: "/System/Applications/Utilities/Terminal.app")
      }
    case .shortcut:
      IconView(path: "/System/Applications/Shortcuts.app")
    case .type:
      FeatureIcon(color: .pink, size: CGSize(width: 28, height: 28), {
        TypingSymbol(foreground: Color.pink)
      }).redacted(reason: .placeholder)
    }
  }
}

struct SearchView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    SearchView(
      applicationStore: applicationStore,
      searchStore: SearchStore(
        store: GroupStore(),
        results: [
          .init(name: "Workflow", kind: .workflow(Workflow.designTime(.application([])))),

            .init(
              name: "Finder",
              kind: .command(.application(.init(application: Application.finder())))),
          .init(
            name: "Calendar",
            kind: .command(.application(.init(application: Application.calendar()))))
        ]))
  }
}
