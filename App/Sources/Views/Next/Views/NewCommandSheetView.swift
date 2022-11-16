import SwiftUI

struct NewCommandSheetView: View {
  enum Action {
    case close
  }
  @ObserveInjection var inject

  private let onAction: (Action) -> Void
  private let imageSize: CGSize = .init(width: 32, height: 32)

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button(action: { onAction(.close) },
               label: { Image(systemName: "xmark") })
        .buttonStyle(.borderless)
        .frame(minWidth: 24, minHeight: 24)
        HStack {
          Spacer()
          Text("Add new command")
            .font(.title2)
            .foregroundColor(Color(nsColor: .headerTextColor))
          Spacer()
        }
      }
      .padding(8)
      

      Divider()

      Grid(horizontalSpacing: 0, verticalSpacing: 0) {
        GridRow {
          featureIcon("Application", color: .red, action: {}) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/Applications"))
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 30)
          }

          featureIcon("Shell script", color: .orange, action: {}) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Terminal.app"))
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 34)
          }

          featureIcon("Apple script", color: .yellow, action: {}) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Script Editor.app"))
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 32)
          }
        }
        .padding()

        GridRow {
          featureIcon("Shortcut", color: Color(.systemPurple), action: {}) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 34)
          }

          featureIcon("Keyboard shortcut", color: .green, action: {}) {
            ModifierKeyIcon(key: .function)
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 27)
          }

          featureIcon("Open file or folder", color: Color(.systemBlue), action: {}) {
            ZStack {
              Image(nsImage: NSWorkspace.shared.icon(forFile: "~/"))
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 30)
                .rotationEffect(.degrees(5))
                .offset(.init(width: 4, height: -2))
              Image(nsImage: NSWorkspace.shared.icon(forFile: "~/".sanitizedPath))
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 30)
            }
          }
        }
        .padding()

        GridRow {
          featureIcon("Open URL", color: .blue, action: {}) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"))
          }

          featureIcon("Typing", color: .pink, action: {}) {
            if let contents = FileManager.default.contents(atPath: "/System/Library/PrivateFrameworks/AOSUI.framework/Versions/A/Resources/pref_notes.icns"),
               let image = NSImage(data: contents) {
              Image(nsImage: image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 34)
            }
          }

          featureIcon("Built-in", color: .gray , action: {}) {
            Image("ApplicationIcon")
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 36)
              .offset(x: -0.5, y: 0.5)
          }
        }
        .padding()
      }
      .padding(8)
      .background(Color(nsColor: .gridColor))
    }
    .frame(width: 600)
    .enableInjection()
  }

  func featureIcon<Content: View>(_ text: String, color: Color,
                                  action: @escaping () -> Void,
                                  @ViewBuilder content: @escaping () -> Content) -> some View {
    Button(action: action) {
      HStack {
        FeatureIcon(color: color, size: imageSize) {
          content()
        }
        .shadow(radius: 4)
        Text(text)
          .fixedSize(horizontal: true, vertical: false)
        Spacer()
      }
    }
    .buttonStyle(.plain)
    .frame(minWidth: 120)
  }
}

struct NewCommandSheetView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandSheetView { _ in }
  }
}
