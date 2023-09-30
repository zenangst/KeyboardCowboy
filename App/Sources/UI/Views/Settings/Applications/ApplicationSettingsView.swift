import Apps
import SwiftUI

struct ApplicationSettingsView: View {
  @EnvironmentObject var openPanel: OpenPanelController
  @AppStorage("additionalApplicationPaths", store: AppStorageStore.store) var additionalApplicationPaths = [String]()

  @State private var isPresentingPopover: Bool = false

  var body: some View {
    ScrollView(.vertical) {
      VStack(alignment: .leading) {
        Text("Additional directories")
          .font(.headline)

        VStack {
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
              }
            }
          }
        }

        Divider()

        HStack {
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
          .buttonStyle(AppButtonStyle(.init(nsColor: .systemBlue)))
          .font(.callout)

          Button(action: {
            isPresentingPopover = true
          }, label: {
            Image(systemName: "questionmark.app.fill")
          })
          .buttonStyle(AppButtonStyle(.init(nsColor: .systemYellow, cornerRadius: 48)))
          .popover(isPresented: $isPresentingPopover,
                   arrowEdge: .bottom,
                   content: {
            ApplicationSettingsPopoverView()
          })
        }

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
    .padding()
    .environmentObject(OpenPanelController())
}
