import Apps
import Bonzai
import Inject
import SwiftUI

struct ApplicationSettingsView: View {
  @ObserveInjection var inject
  @EnvironmentObject var openPanel: OpenPanelController
  @AppStorage("additionalApplicationPaths", store: AppStorageContainer.store) var additionalApplicationPaths = [String]()

  @State private var isPresentingPopover: Bool = false

  var body: some View {
    VStack {
      HStack(alignment: .bottom) {
        ZenLabel(.detail, content: { Text("Additional Applications")})
          .style(.derived)
        Spacer()
      }
      .padding(.top, 8)

      Group {
        if additionalApplicationPaths.isEmpty {
          Text("No additional directories")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView(.vertical) {
            VStack(alignment: .leading) {
              ForEach(additionalApplicationPaths, id: \.self) { path in
                HStack {
                  Text(path)
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Button(action: {
                    additionalApplicationPaths.removeAll(where: { $0 == path })
                    Task { await ApplicationStore.shared.load() }
                  }, label: {
                    Image(systemName: "trash")
                  })
                }
                Divider()
              }
              .style(.item)
            }
            .frame(maxHeight: .infinity)
          }
          .style(.list)
        }
      }
      .roundedStyle()
      .layoutPriority(100)

      HStack {
        Button(action: {
          isPresentingPopover = true
        }, label: {
          Image(systemName: "questionmark.app.fill")
        })
        .popover(isPresented: $isPresentingPopover,
                 arrowEdge: .bottom,
                 content: {
          ApplicationSettingsPopoverView()
        })
        .buttonStyle(.help)

        Spacer()
        Button(action: {
          openPanel.perform(.selectFolder(allowMultipleSelections: true, handler: { string in
            guard !additionalApplicationPaths.contains(string) else { return }
            additionalApplicationPaths.append(string)
            Task { await ApplicationStore.shared.load() }
          }))
        }, label: {
          HStack(spacing: 4) {
            Image(systemName: "folder")
            Divider()
            Text("Add Folder")
          }
        })
        .font(.callout)
      }

      Spacer()
    }
    .style(.derived)
    .style(.section(.detail))
    .frame(minWidth: 480, minHeight: 160)
    .enableInjection()
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
