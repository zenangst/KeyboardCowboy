import SwiftUI
import ModelKit

// swiftlint:disable line_length
struct EditGroup: View {
  @State private var showColorPopover = false
  @State private var hoverText: String = ""
  @State private var name: String
  @State private var symbol: String
  @State private var color: String
  @State private var bundleIdentifiers: Set<String>
  @State private var selectedApplicationIndex: Int = 0
  var installedApplications: [Application]
  private var editAction: (String, String, String, [String]) -> Void
  private var cancelAction: () -> Void

  init(name: String,
       color: String,
       symbol: String,
       bundleIdentifiers: [String],
       applicationProvider: ApplicationProvider,
       editAction: @escaping (String, String, String, [String]) -> Void,
       cancelAction: @escaping () -> Void) {
    _color = State(initialValue: color)
    _name = State(initialValue: name)
    _symbol = State(initialValue: symbol)
    _bundleIdentifiers = State(initialValue: Set<String>(bundleIdentifiers))
    self.editAction = editAction
    self.cancelAction = cancelAction
    self.installedApplications = applicationProvider.state
  }

  var body: some View {
    VStack(spacing: 0) {
      headerView.padding()
      Divider().padding(.vertical, 8)
      VStack(alignment: .leading) {
        applicationRules
      }
      .frame(minHeight: 320, maxHeight: .infinity, alignment: .topLeading)
      .frame(width: 480)
      .padding()
      Divider()
      buttons.padding(.all, 10)
    }
  }
}

private extension EditGroup {
  @ViewBuilder
  var headerView: some View {
    HStack(alignment: .center) {
      icon
        .padding()
        .onTapGesture(perform: {
          showColorPopover = true
        })
      VStack(alignment: .leading) {
        Text("\"\(name)\" info").bold()
        HStack {
          nameView
        }
      }
    }
  }

  var icon: some View {
    ZStack {
      ColorView($color, selectAction: { _ in })
      Image(systemName: symbol).renderingMode(.template).foregroundColor(.white)
      Text(hoverText)
        .allowsHitTesting(false)
        .foregroundColor(.white)
        .font(.caption)
        .offset(x: 0, y: 12)
    }
    .frame(width: 36, height: 36)
    .onHover(perform: { hovering in
      hoverText = hovering ? "Edit" : ""
    })
    .popover(isPresented: $showColorPopover, content: {
      EditGroupPopover(selectColor: selectColor(_:),
                       selectSymbol: selectSymbol(_:))
        .padding()
    })
  }

  var nameView: some View {
    Group {
      Text("Name:")
      TextField("", text: $name)
    }
  }

  var applicationView: some View {
    Group {
      Picker("Application:", selection: Binding(get: {
        selectedApplicationIndex
      }, set: {
        selectedApplicationIndex = $0
      })) {
        ForEach(0..<installedApplications.count, id: \.self) { index in
          Text(installedApplications[index].displayName).tag(index)
        }
      }
    }
  }

  @ViewBuilder
  var applicationRules: some View {
    Text("Rules").font(.headline)
    HStack {
      applicationView
      Spacer()
      Button("+", action: {
        bundleIdentifiers.insert(
          installedApplications[selectedApplicationIndex].bundleIdentifier
        )
      })
    }
    if !bundleIdentifiers.isEmpty {
      applicationList
    }
    Text("Workflows in this group are only activated when the following applications are the frontmost application. The order of this list is irrelevant. If this list is empty, then the workflows are considered global.").font(.caption)
  }

  var applicationList: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(installedApplications.filter({ bundleIdentifiers.contains($0.bundleIdentifier) }), id: \.id) { application in
          VStack(spacing: 0) {
            HStack {
              IconView(path: application.path)
              Text(application.displayName)
              Spacer()
              Button("-", action: {
                if let index = bundleIdentifiers.firstIndex(of: application.bundleIdentifier) {
                  bundleIdentifiers.remove(at: index)
                }
              }).frame(width: 36, height: 36)
            }
            Divider()
          }.padding(.horizontal, 8)
        }
      }
    }
    .background(Color(.textBackgroundColor))
    .frame(minHeight: 72)
  }

  var buttons: some View {
    HStack {
      Spacer()
      Button(action: cancelAction, label: {
        Text("Cancel").frame(minWidth: 60)
      }).keyboardShortcut(.cancelAction)

      Button(action: { editAction(name, color, symbol, Array(bundleIdentifiers)) }, label: {
        Text("OK").frame(minWidth: 60)
      }).keyboardShortcut(.defaultAction)
    }
  }

  func selectColor(_ newColor: String) {
    color = newColor
  }

  func selectSymbol(_ newSymbol: String) {
    symbol = newSymbol
  }
}

struct EditGroup_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditGroup(
      name: "Global shortcuts",
      color: "#EB4B63",
      symbol: "folder",
      bundleIdentifiers: [
        "com.apple.finder",
        "com.apple.music"
      ],
      applicationProvider: ApplicationPreviewProvider().erase(),
      editAction: { _, _, _, _ in },
      cancelAction: {}
    ).fixedSize()
  }
}
