import Carbon
import SwiftUI

struct NewCommandSheetView: View {
  enum Action {
    case newCommand(Kind)
    case close
  }

  enum Kind {
    case application
    case shell
    case appleScript
    case shortcut
    case keyboardShortcut
    case open(path: String)
    case url(urlString: String)
    case typing(input: String)
    case builtin
  }

  @Namespace var namespace
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

      VStack {

//      Grid(horizontalSpacing: 0, verticalSpacing: 0) {
//        GridRow {
          NewCommandSheetButton("Application", color: .red, size: imageSize, action: {
            onAction(.newCommand(.application))
          }, onKeyDown: onKeyDown) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/Applications"))
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 30)
          }

          NewCommandSheetButton("Shell script", color: .orange, size: imageSize, action: {
            onAction(.newCommand(.shell))
          }, onKeyDown: onKeyDown) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Terminal.app"))
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 34)
          }

          NewCommandSheetButton("Apple script", color: .yellow, size: imageSize, action: {
            onAction(.newCommand(.appleScript))
          }, onKeyDown: onKeyDown) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Script Editor.app"))
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 32)
          }
//        }
//        .padding()

//        GridRow {
          NewCommandSheetButton("Shortcut", color: Color(.systemPurple), size: imageSize, action: {
            onAction(.newCommand(.shortcut))
          }, onKeyDown: onKeyDown) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 34)
          }

          NewCommandSheetButton("Keyboard shortcut", color: .green, size: imageSize, action: {
            onAction(.newCommand(.keyboardShortcut))
          }, onKeyDown: onKeyDown) {
            ModifierKeyIcon(key: .function)
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 27)
          }

          NewCommandSheetButton("Open file or folder", color: Color(.systemBlue), size: imageSize, action: {
            onAction(.newCommand(.open(path: "path")))
          }, onKeyDown: onKeyDown) {
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
//        }
//        .padding()

//        GridRow {
          NewCommandSheetButton("Open URL", color: .blue, size: imageSize, action: {
            onAction(.newCommand(.url(urlString: "Url")))
          }, onKeyDown: onKeyDown) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"))
          }

          NewCommandSheetButton("Typing", color: .pink, size: imageSize, action: {
            onAction(.newCommand(.typing(input: "Input")))
          }, onKeyDown: onKeyDown) {
            if let contents = FileManager.default.contents(atPath: "/System/Library/PrivateFrameworks/AOSUI.framework/Versions/A/Resources/pref_notes.icns"),
               let image = NSImage(data: contents) {
              Image(nsImage: image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 34)
            }
          }

          NewCommandSheetButton("Built-in", color: .gray, size: imageSize, action: {
            onAction(.newCommand(.builtin))
          }, onKeyDown: onKeyDown) {
            Image("ApplicationIcon")
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .frame(width: 36)
              .offset(x: -0.5, y: 0.5)
          }
//        }
//        .padding()
      }
      .padding(8)
      .background(Color(nsColor: .gridColor))
    }
    .frame(width: 600)
    .focusSection()
    .focusScope(namespace)
    .enableInjection()
  }

  private func onKeyDown(keyCode: Int, modifiers: NSEvent.ModifierFlags) {
    if keyCode == kVK_Return {

    }
  }
}

struct NewCommandSheetButton<Content>: View where Content: View {
  @ObserveInjection var inject
  @Environment(\.controlActiveState) var controlActiveState
  @FocusState var isFocused: Bool
  @State private var isPresented: Bool = false
  @State private var text: String
  private let color: Color
  private let size: CGSize
  private let action: () -> Void
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void
  private let content: () -> Content

  init(_ text: String,
       color: Color,
       size: CGSize,
       action: @escaping () -> Void,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void,
       @ViewBuilder content: @escaping () -> Content) {
    _text = .init(initialValue: text)
    self.color = color
    self.size = size
    self.action = action
    self.onKeyDown = onKeyDown
    self.content = content
  }

  var body: some View {
//    Button(action: {
//
//    }) {
      HStack {
        Group {
          FeatureIcon(color: color, size: size) {
            content()
          }
          .shadow(radius: 4)
          Text(text)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(isFocused ? .white : Color(.textColor))
        }
        .allowsHitTesting(false)

        Spacer()
      }
      .padding(.leading, 2)
      .padding(.vertical, 2)
//    }
//    .buttonStyle(.appStyle)
    .background(
      ZStack {
        FocusableProxy(id: UUID().uuidString, onKeyDown: { keyCode, modifiers in
          if keyCode == kVK_Return {
            isPresented = true
//            action()
          }
          onKeyDown(keyCode, modifiers)
        })
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(.controlAccentColor), lineWidth: 2)
          .opacity(isFocused ? 1 : 0)
      }
    )
    //    .shadow(color: isFocused ? .accentColor.opacity(controlActiveState == .key ? 0.8 : 0.4) : Color(.sRGBLinear, white: 0, opacity: 0.33),
    //            radius: isFocused ? 1.0 : 0.0)
    .menuStyle(.borderlessButton)
    .frame(minWidth: 120)
    .focusable()
    .focused($isFocused)
    .enableInjection()
  }
}

struct NewCommandSheetView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandSheetView { _ in }
  }
}
