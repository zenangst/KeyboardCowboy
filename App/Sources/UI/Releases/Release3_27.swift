import Bonzai
import Inject
import SwiftUI

struct Release3_27: View {
  @ObserveInjection var inject
  enum ButtonAction {
    case done
  }

  let size: CGFloat = 96
  let action: (ButtonAction) -> Void

  var body: some View {
    VStack(spacing: 8) {
      Text("What's New")
        .font(.headline)
        .padding(.top, 6)
      HeaderView()
        .overlay(alignment: .bottom) {
          HeaderOverlay(size: size)
        }

      ZenDivider(.horizontal)

      VStack(alignment: .leading, spacing: 0) {
        ChangesView()
        Divider()
        SupportersView()
          .frame(height: 150)
      }
      .roundedStyle(padding: 0)
      .style(.derived)

      Button(action: { action(.done) }, label: { Text("Let's Get Started!") })
        .buttonStyle(.positive)
        .environment(\.buttonHoverEffect, false)
        .environment(\.buttonPadding, .large)
        .environment(\.buttonBackgroundColor, .systemGreen)
        .style(.derived)
    }
    .style(.derived)
    .style(.section(.detail))
    .background(
      ZStack {
        ZenVisualEffectView(material: .hudWindow)
          .mask {
            LinearGradient(
              stops: [
                .init(color: .black, location: 0),
                .init(color: .clear, location: 1),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          }
        ZenVisualEffectView(material: .contentBackground)
          .mask {
            LinearGradient(
              stops: [
                .init(color: .black.opacity(0.5), location: 0),
                .init(color: .black, location: 0.75),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          }
      }
    )
    .ignoresSafeArea(.all)
    .frame(width: 550, height: 650)
    .enableInjection()
  }
}

private struct HeaderView: View {
  var body: some View {
    HStack(alignment: .bottom, spacing: -16) {
      let iconSize: CGFloat = 96
      WindowSwitcherIconView(size: iconSize)
        .rotation3DEffect(.degrees(10), axis: (x: 1, y: 1, z: -1))
        .zIndex(9)
      InputSourceIcon(size: iconSize)
        .rotation3DEffect(.degrees(7.5), axis: (x: 1, y: 1, z: -1))
        .zIndex(9)

      ImprovementIconView(size: iconSize)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: 1))
        .shadow(radius: 30)
        .zIndex(10)
      ScriptIconView(size: iconSize)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: -1))
        .shadow(radius: 30)
        .zIndex(10)

      WindowTidyIcon(size: iconSize)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: 1))
        .shadow(radius: 30)
        .zIndex(10)
      WorkspaceIcon(size: iconSize)
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
      Text("3.27.2")
        .foregroundStyle(.white)
        .font(Font.system(size: 24, design: .rounded))
        .allowsTightening(true)
        .fontWeight(.heavy)
        .shadow(color: Color(.systemOrange), radius: 10)
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
           text: "Fix bug where keyboard sequences became unreliable.",
           version: .v3272),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fix bug where new Workspace ended up adding an App Focus command.",
           version: .v3271),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "Improve performance when handling repeating keyboard events that don't match a workflow.",
           version: .v3271),

    Change(icon: { ScriptIconView(size: 24).anyView },
           text: "Improve shell scripting errors by showing the error message in the notification.",
           version: .v3271),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fix bug where PATH environment is not set properly when using shebangs.",
           version: .v3271),

    Change(icon: { WindowSwitcherIconView(size: 24).anyView },
           text: "**NEW**: Switch between open windows using the new **Window Switcher**.",
           version: .v3270),

    Change(icon: { InputSourceIcon(size: 24).anyView },
           text: "**NEW**: Change the input source with the new **Input Source** command.",
           version: .v3270),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "**NEW**: Redesigned UX for adding new commands.",
           version: .v3270),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "**NEW**: Introduced a new notification style called **Capsule**.",
           version: .v3270),

    Change(icon: { WindowTilingIcon(kind: .left, size: 24).anyView },
           text: "Bug fixes when using macOS Sequoia window tiling.",
           version: .v3270),

    Change(icon: { ScriptIconView(size: 24).anyView },
           text: "**Shell scripts** now respect shebang (`#!`).",
           version: .v3270),

    Change(icon: { ScriptIconView(size: 24).anyView },
           text: "**JXA AppleScript** variants are now supported. Happy scripting!",
           version: .v3270),

    Change(icon: { SnippetIconView(size: 24).anyView },
           text: "**Snippets** no longer have a timeout, making them more reliable.",
           version: .v3270),

    Change(icon: { WindowTilingIcon(kind: .left, size: 24).anyView },
           text: "Bug fixes when using macOS Sequoia window tiling.",
           version: .v3270),

    Change(icon: { WorkspaceIcon(size: 24).anyView },
           text: "Bug fixes in the **Workspace Command**.",
           version: .v3270),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "**Raycast extensions** now integrate more smoothly with Keyboard Cowboy.",
           version: .v3270),
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
                .padding(.vertical, 4)
              let markdown: LocalizedStringKey = LocalizedStringKey(change.text)
              Text(markdown)
                .tint(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
              Button(action: {  }, label: {
                Text(change.version.rawValue)
                  .font(.caption)
              })
              .environment(\.buttonBackgroundColor, change.version.color)
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

    Supporter(
      index: 15,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/146323001?s=200&v=4"),
      githubHandle: "lo-cafe"),

    Supporter(
      index: 16,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/45841003?v=4"),
      githubHandle: "TaylorJKing"),

    Supporter(
      index: 16,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/227768?v=4"),
      githubHandle: "brunns"),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Special thanks to")
        .font(Font.system(.headline, weight: .bold))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.top, .leading] ,8)

      ZenDivider(.horizontal)

      ScrollView {
        FlowLayout(itemSpacing: 0, lineSpacing: 0) {
          ForEach(supporters, id: \.self) { supporter in
            if supporter.index == supporters.count - 1 {
              Text("&")
                .fontWeight(.bold)
            }
            SupporterView(imageUrl: supporter.imageUrl, githubHandle: supporter.githubHandle)
          }
          .frame(height: 24)
        }
        .padding(8)
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
  }
}

private struct Supporter: Hashable {
  let index: Int
  let imageUrl: URL?
  let githubHandle: String
}

private enum Version: String, Equatable {
  case v3275 = "3.27.5"
  case v3274 = "3.27.4"
  case v3273 = "3.27.3"
  case v3272 = "3.27.2"
  case v3271 = "3.27.1"
  case v3270 = "3.27.0"

  var color: Color {
    switch self {
    case .v3275: Color(.systemBlue)
    case .v3274: Color(.systemGreen)
    case .v3273: Color(.systemYellow)
    case .v3272: Color(.systemOrange)
    case .v3271: Color(.systemRed)
    case .v3270: Color(.systemPurple)
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

struct Release3_27_Previews: PreviewProvider {
  static var previews: some View {
    Release3_27 { _ in }
      .previewDisplayName("Release 3.27")
  }
}
