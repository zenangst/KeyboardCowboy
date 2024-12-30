import Bonzai
import Inject
import SwiftUI

struct Release3_26: View {
  @ObserveInjection var inject
  enum ButtonAction {
    case done
  }

  let size: CGFloat = 96
  let action: (ButtonAction) -> Void

  var body: some View {
    VStack(spacing: 8) {
      Text("What's New")
      HeaderView()
        .overlay(alignment: .bottom) {
          HeaderOverlay(size: size)
        }
        .padding([.top, .bottom], 16)

      ZenDivider(.horizontal)

      VStack(alignment: .leading, spacing: 0) {
        ChangesView()
        Divider()
        SupportersView()
          .frame(height: 125)
      }
      .roundedContainer(padding: 0, margin: 16)
      .padding(.top, 8)

      HStack(spacing: 8) {
        Button(action: { action(.done) }, label: { Text("To the Moon! 🚀🌘") })
          .buttonStyle(.zen(.init(color: .systemGreen, hoverEffect: .constant(false))))
      }
      .padding(.bottom, 32)
    }
    .background(Color(.windowBackgroundColor))
    .frame(width: 550, height: 650)
    .enableInjection()
  }
}

private struct HeaderView: View {
  var body: some View {
    HStack(alignment: .bottom, spacing: -16) {
      WindowSwitcherIconView(size: 128)
        .rotation3DEffect(.degrees(10), axis: (x: 1, y: 1, z: -1))
        .zIndex(9)
      ImprovementIconView(size: 128)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: 1))
        .shadow(radius: 30)
        .zIndex(10)
      KeyboardIconView("M", size: 128)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: -1))
        .shadow(radius: 30)
        .zIndex(10)
      WorkspaceIcon(size: 128)
        .rotation3DEffect(.degrees(10), axis: (x: 1, y: 0, z: 1))
        .zIndex(9)
    }
  }
}

private struct HeaderOverlay: View {
  let size: CGFloat

  var body: some View {
    HStack(alignment: .center) {
      Text("Keyboard Cowboy")
        .font(Font.system(size: 20, design: .rounded))
      Text("3.26")
        .foregroundStyle(.white)
        .font(Font.system(size: 24, design: .rounded))
        .allowsTightening(true)
        .fontWeight(.heavy)
        .shadow(color: Color(.systemRed), radius: 10)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 16)
    .shadow(radius: 2)
    .fixedSize()
    .background {
      Rectangle()
        .fill(
          LinearGradient(
            stops: [
              Gradient.Stop(color: .black.opacity(0.75), location: 0.5),
              Gradient.Stop(color: .black, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .overlay {
          AngularGradient(stops: [
            .init(color: Color.clear, location: 0.0),
            .init(color: Color.white.opacity(0.2), location: 0.2),
            .init(color: Color.clear, location: 1.0),
          ], center: .bottomLeading)

          LinearGradient(stops: [
            .init(color: Color.white.opacity(0.2), location: 0),
            .init(color: Color.clear, location: 0.3),
          ], startPoint: .top, endPoint: .bottom)

          LinearGradient(stops: [
            .init(color: Color.clear, location: 0.8),
            .init(color: Color(.windowBackgroundColor).opacity(0.3), location: 1.0),
          ], startPoint: .top, endPoint: .bottom)
        }
    }
    .iconShape(size)
    .offset(y: 16)
  }
}

private struct ChangesView: View {
  @ObserveInjection var inject

  private let changes: [Change<AnyView>] = [
    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Improve reliability of AppFocus & Workspace commands.",
           version: .v3261),

    Change(icon: { WorkspaceIcon(size: 24).anyView },
           text: "This update lets you turn off tiling for existing AppFocus and Workspace commands.",
           version: .v3261),

    Change(icon: { GenericAppIconView(size: 24).anyView },
           text: "Sort applications by display name.",
           version: .v3261),

    Change(icon: { WindowSwitcherIconView(size: 24).anyView },
           text: "Introduces the first version of the new Window Switcher.",
           version: .v3260),

    Change(icon: { UIElementIconView(size: 24).anyView },
           text: "Guess what? UIElement commands now have a new feature called 'subrole' that helps you match them. A big thanks to [@FischLu](https://github.com/FischLu) for making this possible!",
           version: .v3260),

    Change(icon: { KeyboardIconView("M", size: 24).anyView },
           text: "Adds the option to turn off key repeat for keyboard triggers.",
           version: .v3260),

    Change(icon: { KeyboardIconView("S", size: 24).anyView },
           text: "We've made a bunch of improvements to figuring out which key is triggered from third-party apps.",
           version: .v3260),

    Change(icon: { WorkspaceIcon(size: 24).anyView },
           text: "Switching between Workspaces is now a breeze!",
           version: .v3260),

    Change(icon: { TypingIconView(size: 24).anyView },
           text: "Type commands now supports 'insert enter' as a completion action.",
           version: .v3260),

    Change(icon: { TriggersIconView(size: 24).anyView },
           text: "Adds support for disabling entire Groups.",
           version: .v3260),

    Change(icon: { TriggersIconView(size: 24).anyView },
           text: "The default workflow option is now serial instead of concurrent.",
           version: .v3260),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Various UI improvements and bug fixes.",
           version: .v3260),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "We've made some tweaks to address those pesky keyboard triggers that were causing some issues.",
           version: .v3260),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Enhancements to keyboard shortcuts that utilize the arrow keys.",
           version: .v3260),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "The configuration file has been shrunk to a manageable size.",
           version: .v3260),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "Migrated to Swift 6.",
           version: .v3260),
  ]

  @ViewBuilder
  var body: some View {
    VStack(spacing: 8) {
      Text("Changes")
        .font(Font.system(.headline, weight: .bold))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.top, .leading] ,8)
      ScrollView(.vertical) {
        Grid(verticalSpacing: 16) {
          ForEach(changes, id: \.text) { change in
            GridRow {
              change.icon
              ZenDivider(.vertical)
              let markdown: LocalizedStringKey = LocalizedStringKey(change.text)
              Text(markdown)
                .tint(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
              Button(action: {  }, label: {
                Text(change.version.rawValue)
                  .font(.caption)
              })
              .buttonStyle(.zen(.init(color: .custom(change.version.color))))
              .padding(.trailing, 4)
            }
          }
        }
        .padding(16)
      }
      .scrollIndicators(.visible)
      .scrollContentBackground(.visible)
      .frame(minHeight: 210)
    }
    .enableInjection()
  }
}

private struct SupportersView: View {
  @ObserveInjection var inject

  private let supporters = [
    Supporter(
      index: 0,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/2284279?v=4"),
      githubHandle: "onmyway133"),

    Supporter(
      index: 1,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/4262050?v=4"),
      githubHandle: "bjrmatos"),

    Supporter(
      index: 2,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/1260095?s=52&v=4")!,
      githubHandle: "andreasoverland"),

    Supporter(
      index: 3,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/68963405?v=4"),
      githubHandle: "MrKai77"),

    Supporter(
      index: 4,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/4584594?s=96&v=4"),
      githubHandle: "murdahl"),

    Supporter(
      index: 5,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/620789?s=96&v=4"),
      githubHandle: "hansoln"),

    Supporter(
      index: 6,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/47497819?v=4"),
      githubHandle: "Moelfarri"),

    Supporter(
      index: 7,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/555305?s=96&v=4"),
      githubHandle: "t0ggah"),

    Supporter(
      index: 8,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/32518292?s=96&v=4"),
      githubHandle: "Abenayan"),

    Supporter(index: 9, imageUrl: URL(string: "https://avatars.githubusercontent.com/u/1581077?v=4"), githubHandle: "fushugaku"),

    Supporter(index: 10, imageUrl: URL(string: "https://avatars.githubusercontent.com/u/105807570?v=4"), githubHandle: "bassamsdata"),

    Supporter(index: 11, imageUrl: URL(string: "https://avatars.githubusercontent.com/u/177531206?v=4"), githubHandle: "StianFlatby"),


    Supporter(
      index: 12,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/378235?v=4"),
      githubHandle: "timkurvers"),

    Supporter(
      index: 13,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/386122?v=4"),
      githubHandle: "sindrenm"),

    Supporter(
      index: 14,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/10261662?v=4"),
      githubHandle: "FischLu"),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Special thanks to")
        .font(Font.system(.headline, weight: .bold))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.top, .leading] ,8)

      ZenDivider(.horizontal)

      ScrollView {
        FlowLayout(itemSpacing: 0) {
          ForEach(supporters, id: \.self) { supporter in
            if supporter.index == supporters.count - 1 {
              Text("&")
                .fontWeight(.bold)
            }
            SupporterView(imageUrl: supporter.imageUrl, githubHandle: supporter.githubHandle)
          }
          .frame(height: 24)
        }
        .padding([.leading, .trailing, .bottom], 8)
      }
    }
    .enableInjection()
  }
}

private struct SupporterView: View {
  let imageUrl: URL?
  let githubHandle: String

  var body: some View {
    Button(action: { }) {
      HStack {
        AsyncImage.init(url: imageUrl) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .mask { Circle() }
        } placeholder: {
          Circle()
            .fill(Color(.controlAccentColor))
            .frame(width: 16, height: 16)
            .overlay {
              ProgressView()
            }
        }
        Link("\(githubHandle)", destination: URL(string: "https://github.com/\(githubHandle)")!)
          .font(.body)
          .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(2)
    .buttonStyle(.zen(.init(
      calm: true,
      color: .accentColor,
      focusEffect: .constant(false),
      padding: .small)))
  }
}

private struct Supporter: Hashable {
  let index: Int
  let imageUrl: URL?
  let githubHandle: String
}

private enum Version: String {
  case v3265 = "3.26.5"
  case v3264 = "3.26.4"
  case v3263 = "3.26.3"
  case v3262 = "3.26.2"
  case v3261 = "3.26.1"
  case v3260 = "3.26.0"

  var color: Color {
    switch self {
    case .v3265: Color(.systemBlue)
    case .v3264: Color(.systemGreen)
    case .v3263: Color(.systemYellow)
    case .v3262: Color(.systemOrange)
    case .v3261: Color(.systemRed)
    case .v3260: Color(.systemPurple)
    }
  }
}

private struct Change<Content> where Content: View {
  let icon: AnyView
  let text: String
  let version: Version

  init(@ViewBuilder icon: @escaping () -> Content, text: String, version: Version) {
    self.icon = AnyView(icon())
    self.text = text
    self.version = version
  }
}

private extension View {
  var anyView: AnyView { AnyView(self) }
}

struct Release3_26_Previews: PreviewProvider {
  static var previews: some View {
    Release3_26 { _ in }
      .previewDisplayName("Release 3.26")
  }
}
