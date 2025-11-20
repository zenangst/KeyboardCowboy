import Bonzai
import Inject
import SwiftUI

private let currentVersion: Version = .v3283

struct Release3_28: View {
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
              endPoint: .bottom,
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
              endPoint: .bottom,
            )
          }
      },
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

      WorkspaceIcon(.regular, size: iconSize)
        .rotation3DEffect(.degrees(10), axis: (x: 1, y: 1, z: -1))
        .zIndex(9)
      MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: iconSize)
        .rotation3DEffect(.degrees(7.5), axis: (x: 1, y: 1, z: -1))
        .zIndex(9)

      WindowTilingIcon(kind: .arrangeLeftQuarters, size: iconSize)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: 1))
        .shadow(radius: 30)
        .zIndex(10)
      ImprovementIconView(size: iconSize)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: -1))
        .shadow(radius: 30)
        .zIndex(10)

      ActivateLastApplicationIconView(size: iconSize)
        .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: 1))
        .shadow(radius: 30)
        .zIndex(10)
      BugFixIconView(size: iconSize)
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
      Text(currentVersion.rawValue)
        .foregroundStyle(.white)
        .font(Font.system(size: 24, design: .rounded))
        .allowsTightening(true)
        .fontWeight(.heavy)
        .shadow(color: currentVersion.color, radius: 10)
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
            endPoint: .bottom,
          ),
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
    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "Improve window focus reliability when using macOS Spaces",
           version: .v3283),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fixes SwiftUI crash related to adding new UI element recordings",
           version: .v3283),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fixes minor UI glitch with capsule notifications",
           version: .v3283),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fixes a performance bug when using Capsule Notifications",
           version: .v3282),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fixes a bug with keyboard shortcuts using the passthrough modifier.",
           version: .v3281),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fixes faulty migrations of script- and keyboard workflows, for some users.",
           version: .v3281),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "Adds support for denied applications when using Groups.",
           version: .v3281),

    Change(icon: { WindowTilingIcon(kind: .arrangeLeftQuarters, size: 24).anyView },
           text: "Improves reliability when tiling windows.",
           version: .v3281),

    Change(icon: { WindowFocusIconBuilder.icon(.moveFocusToNextWindowGlobal, size: 24).anyView },
           text: "Improves reliability when switching focus between windows.",
           version: .v3281),

    Change(icon: { WorkspaceIcon(.regular, size: 24).anyView },
           text: "Performance improvements when switching workspaces.",
           version: .v3280),

    Change(icon: { WorkspaceIcon(.regular, size: 24).anyView },
           text: "Adds support for \"only when open\" option for applications attached to a workspace",
           version: .v3280),

    Change(icon: { WorkspaceIcon(.regular, size: 24).anyView },
           text: "Improve workspaces when Stage Manager is enabled.",
           version: .v3280),

    Change(icon: { WorkspaceIcon(.regular, size: 24).anyView },
           text: "Add support for peek when using activate last application or workspace.",
           version: .v3280),

    Change(icon: { MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: 24).anyView },
           text: "Improve the algorithm to make it more stable when windows are created or closed.",
           version: .v3280),

    Change(icon: { WindowTilingIcon(kind: .arrangeLeftQuarters, size: 24).anyView },
           text: "Toggling fill is now more reliable.",
           version: .v3280),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "Add support for hiding the menu bar icon.",
           version: .v3280),

    Change(icon: { ImprovementIconView(size: 24).anyView },
           text: "Under-the-hood performance improvements for common tasks.",
           version: .v3280),

    Change(icon: { ActivateLastApplicationIconView(size: 24).anyView },
           text: "Add support for Orion Web Apps",
           version: .v3280),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fixes a window focus bug",
           version: .v3280),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fixes a bug where shortcuts wouldnt show up.",
           version: .v3280),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Fixes a crash related to window focus.",
           version: .v3280),

    Change(icon: {
             RegularKeyIcon(letter: "l", width: 24, height: 24)
               .fixedSize()
               .anyView
           },
           text: "Add support for leader keys.",
           version: .v3280),
  ]

  var body: some View {
    VStack(spacing: 8) {
      Text("Changes")
        .font(Font.system(.headline, weight: .bold))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.top, .leading], 8)
      ScrollView(.vertical) {
        Grid(verticalSpacing: 16) {
          ForEach(changes, id: \.text) { change in
            GridRow {
              change.icon
              ZenDivider(.vertical)
                .padding(.vertical, 4)
              let markdown = LocalizedStringKey(change.text)
              Text(markdown)
                .tint(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
              Button(action: {}, label: {
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
      githubHandle: "onmyway133",
    ),

    Supporter(
      index: 1,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/4262050?v=4"),
      githubHandle: "bjrmatos",
    ),

    Supporter(
      index: 2,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/1260095?s=52&v=4")!,
      githubHandle: "andreasoverland",
    ),

    Supporter(
      index: 3,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/68963405?v=4"),
      githubHandle: "MrKai77",
    ),

    Supporter(
      index: 4,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/4584594?s=96&v=4"),
      githubHandle: "murdahl",
    ),

    Supporter(
      index: 5,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/620789?s=96&v=4"),
      githubHandle: "hansoln",
    ),

    Supporter(
      index: 6,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/47497819?v=4"),
      githubHandle: "Moelfarri",
    ),

    Supporter(
      index: 7,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/555305?s=96&v=4"),
      githubHandle: "t0ggah",
    ),

    Supporter(
      index: 8,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/32518292?s=96&v=4"),
      githubHandle: "Abenayan",
    ),

    Supporter(index: 9, imageUrl: URL(string: "https://avatars.githubusercontent.com/u/1581077?v=4"), githubHandle: "fushugaku"),

    Supporter(index: 10, imageUrl: URL(string: "https://avatars.githubusercontent.com/u/105807570?v=4"), githubHandle: "bassamsdata"),

    Supporter(index: 11, imageUrl: URL(string: "https://avatars.githubusercontent.com/u/177531206?v=4"), githubHandle: "StianFlatby"),

    Supporter(
      index: 12,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/378235?v=4"),
      githubHandle: "timkurvers",
    ),

    Supporter(
      index: 13,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/386122?v=4"),
      githubHandle: "sindrenm",
    ),

    Supporter(
      index: 14,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/10261662?v=4"),
      githubHandle: "FischLu",
    ),

    Supporter(
      index: 15,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/146323001?s=200&v=4"),
      githubHandle: "lo-cafe",
    ),

    Supporter(
      index: 16,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/45841003?v=4"),
      githubHandle: "TaylorJKing",
    ),

    Supporter(
      index: 16,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/227768?v=4"),
      githubHandle: "brunns",
    ),

    Supporter(
      index: 17,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/2263015?v=4"),
      githubHandle: "hakonk",
    ),

    Supporter(
      index: 18,
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/49613199?v=4"),
      githubHandle: "vlntn-t",
    ),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Special thanks to")
        .font(Font.system(.headline, weight: .bold))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.top, .leading], 8)

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
    Button(action: {}) {
      HStack {
        AsyncImage(url: imageUrl) { image in
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
  case v3283 = "3.28.3"
  case v3282 = "3.28.2"
  case v3281 = "3.28.1"
  case v3280 = "3.28.0"

  var color: Color {
    switch self {
    case .v3280: Color(.systemPurple)
    case .v3281: Color(.systemRed)
    case .v3282: Color(.systemOrange)
    case .v3283: Color(.systemYellow)
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

struct Release3_28_Previews: PreviewProvider {
  static var previews: some View {
    Release3_28 { _ in }
      .previewDisplayName("Release 3.28")
  }
}
