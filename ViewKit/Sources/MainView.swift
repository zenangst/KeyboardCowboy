import SwiftUI

struct MainView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
#endif
