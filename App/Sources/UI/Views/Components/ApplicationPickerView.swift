import Apps
import SwiftUI

struct ApplicationPickerView: View {
  @ObservedObject var store: ApplicationStore
  @Binding var selection: Application?
  private var title: String

  init(_ store: ApplicationStore,
       title: String = "Application:",
       selection: Binding<Application?>) {
    _store = .init(initialValue: store)
    _selection = selection
    self.title = title
  }

  var body: some View {
    Picker(title, selection: $selection) {
      ForEach(store.applications, id: \.bundleIdentifier) { application in
        Text(application.displayName)
          .tag(application as Application?)
      }
    }
  }
}

struct ApplicationSelectorView_Previews: PreviewProvider {
  static let application: Application = .finder()
  static var previews: some View {
    ApplicationPickerView(
      applicationStore,
      selection: .constant(application),
    )
  }
}
