import Bonzai
import Inject
import SwiftUI

struct Release3_25_1: View {
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
        Button(action: { action(.done) }, label: { Text("Maxiumum Effort! 🏴‍☠️") })
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
      WindowTilingIcon(kind: .arrangeLeftQuarters, size: 128)
        .rotation3DEffect(.degrees(10), axis: (x: 1, y: 1, z: -1))
        .zIndex(9)
      WorkspaceIcon(size: 128)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: 1))
        .shadow(radius: 30)
        .zIndex(10)
      AppPeekIcon(size: 128)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: -1))
        .shadow(radius: 30)
        .zIndex(10)
      AppFocusIcon(size: 128)
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
      Text("3.25.2")
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
    Change(icon: { RelativeFocusIconView(.up, size: 24).anyView },
           text: "Fixes a bug where a stray mouse click event might get emitted if relative focus involved Control to activate.",
           version: .v3252),

    Change(icon: { KeyboardIconView("M", size: 24).anyView },
           text: "Fixes a bug where Home, End, and Page Up/Down commands didn't map properly.",
           version: .v3252),

    Change(icon: { AppFocusIcon(size: 24).anyView },
           text: "Adds support for current application when using App Focus commands.",
           version: .v3252),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fix visual glitch when App Focus & Workspace commands didn't have tiling set.",
           version: .v3252),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "Fix CPU spikes and reduce the memory footprint.",
           version: .v3252),

    Change(icon: { WindowManagementIconView(size: 24).anyView },
           text: "Improved Keyboard Cowboys internal window handling.",
           version: .v3252),

    Change(icon: { KeyboardIconView("#", size: 24).anyView },
           text: "Map numpad keys to your hearts content.",
           version: .v3251),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "The internals are now faster than ever.",
           version: .v3251),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fixes for migrating the configuration file to its new location.",
           version: .v3251),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "A quick fix for contextual menus not working on macOS Sonoma.",
           version: .v3251),

    Change(icon: { WorkspaceIcon(size: 24).anyView },
           text: "Level up your macOS productivity with Workspaces.",
           version: .v3250),

    Change(icon: { WindowTilingIcon(kind: .arrangeLeftQuarters, size: 24).anyView },
           text: "Smart Window Tiling in macOS Sequoia.",
           version: .v3250),

    Change(icon: { AppFocusIcon(size: 24).anyView },
           text: "Get your focus on with the new App Focus command.",
           version: .v3250),

    Change(icon: { AppPeekIcon(size: 24).anyView },
           text: "Quick peek at your apps with the new peek functionality for the application command.",
           version: .v3250),

    Change(icon: { RelativeFocusIconView(.upperRight, size: 24).anyView },
           text: "Fly between applications with the new quarter & center focus commands.",
           version: .v3250),

    Change(icon: { RepeatLastWorkflowIconView(size: 24).anyView },
           text: "Easily repeat your last workflow or keyboard event.",
           version: .v3250),

    Change(icon: { HideAllIconView(size: 24).anyView },
           text: "Clean up your workspace with the new smart hide all other apps command.",
           version: .v3250),

    Change(icon: { KeyboardCleanerIcon(size: 24, animated: false).anyView },
           text: "Clean your keyboard has never been easier with 'Keyboard Cleaner'.",
           version: .v3250),

    Change(icon: { GenericAppIconView(size: 24).anyView },
           text: "Application commands now support 'wait until launched'.",
           version: .v3250),

    Change(icon: { ActivateLastApplicationIconView(size: 24).anyView },
           text: "Activating the last application command is now more reliable.",
           version: .v3250),

    Change(icon: { MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: 24).anyView },
           text: "Moving focus between windows is now more accurate.",
           version: .v3250),

    Change(icon: { MacroIconView(.record, size: 24).anyView },
           text: "You can now prefix macros with iterations.",
           version: .v3250),

    Change(icon: { RelativeFocusIconView(.right, size: 24).anyView },
           text: "The scanning algorithm has been completely rewritten to improve relative focus.",
           version: .v3250),

    Change(icon: { WindowManagementIconView(size: 24).anyView },
           text: "Moving windows between monitors is now more accurate.",
           version: .v3250),

    Change(icon: { TriggersIconView(size: 24).anyView },
           text: "Application Triggers now support 'any Application'.",
           version: .v3250),

    Change(icon: { UIImprovementIconView(size: 24).anyView },
           text: "Notifications is now powered by DynamicNotchKit.",
           version: .v3250),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Loads of bug fixes!",
           version: .v3250),

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
              Text(change.text)
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
  case v3252 = "3.25.2"
  case v3251 = "3.25.1"
  case v3250 = "3.25.0"

  var color: Color {
    switch self {
    case .v3252: Color(.systemYellow)
    case .v3251: Color(.systemRed)
    case .v3250: Color(.systemPurple)
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

struct Release3_25_1_Previews: PreviewProvider {
  static var previews: some View {
    Release3_25_1 { _ in }
      .previewDisplayName("Release 3.25.2")
  }
}
