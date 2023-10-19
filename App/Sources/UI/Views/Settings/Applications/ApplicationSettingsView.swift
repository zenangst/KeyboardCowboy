import Apps
import SwiftUI
import Bonzai

struct ApplicationSettingsView: View {
  @EnvironmentObject var openPanel: OpenPanelController
  @AppStorage("additionalApplicationPaths", store: AppStorageStore.store) var additionalApplicationPaths = [String]()

  @State private var isPresentingPopover: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .bottom) {
        Label("Additional Directories", image: "")
          .labelStyle(HeaderLabelStyle())
        Spacer()
      }
      .padding([.top, .leading, .trailing], 16)
      .background(Color(.windowBackgroundColor))

      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 0) {
          if additionalApplicationPaths.isEmpty {
            Text("No additional directories")
              .frame(maxWidth: .infinity)
          } else {
            ForEach(additionalApplicationPaths, id: \.self) { path in
              HStack {
                Text(path)
                  .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: {
                  additionalApplicationPaths.removeAll(where: { $0 == path })
                }, label: {
                  Image(systemName: "trash")
                })
                .buttonStyle(.calm(color: .systemRed, padding: .medium))
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              Divider()
            }
          }
        }
        .frame(maxHeight: .infinity)
      }
      .background(Color(.windowBackgroundColor))
      .layoutPriority(100)

      HStack {
        Button(action: {
          isPresentingPopover = true
        }, label: {
          Image(systemName: "questionmark.app.fill")
        })
        .buttonStyle(.calm(color: .systemYellow, padding: .medium))
        .popover(isPresented: $isPresentingPopover,
                 arrowEdge: .bottom,
                 content: {
          ApplicationSettingsPopoverView()
        })
        Spacer()
        Button(action: {
          openPanel.perform(.selectFolder(handler: { string in
            guard !additionalApplicationPaths.contains(string) else { return }
            additionalApplicationPaths.append(string)
          }))
        }, label: {
          HStack(spacing: 4) {
            Image(systemName: "folder")
            Divider()
            Text("Add Folder")
          }
        })
        .buttonStyle(.zen(.init(color: .systemBlue)))
        .font(.callout)
      }
      .padding(16)
    }
    .frame(minWidth: 480, minHeight: 160)
  }
}

struct ApplicationSettingsPopoverView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Text("Default search directories")
        .font(.headline)
        .padding(.horizontal)
      Divider()
        .padding(.bottom)
      ForEach(ApplicationController.commonPaths(), id: \.self) { url in
        Text(url.absoluteString.replacingOccurrences(of: "file://", with: ""))
          .padding(.horizontal)
      }
      .font(.footnote)
    }
    .padding(.vertical)
  }
}

#Preview {
  ApplicationSettingsView()
    .environmentObject(OpenPanelController())
}
