import Apps
import SwiftUI

struct ApplicationPickerView: View {
  let add: (Application) -> Void
  let applications: [Application]
  @State var selection: String

  init(_ applications: [Application],
       add: @escaping (Application) -> Void) {
    self.add = add
    self.applications = applications
    _selection = .init(initialValue: applications.first?.bundleIdentifier ?? "")
  }

  var body: some View {
    HStack {
      Picker("Application", selection: $selection) {
        ForEach(applications, id: \.bundleIdentifier) { application in
          Text(application.displayName)
            .id(application.bundleIdentifier)
        }
      }
      Button("Add") {
        guard let application = applications.first(where: {
          $0.bundleIdentifier == selection
        }) else { return }
        add(application)
      }
    }
  }
}
