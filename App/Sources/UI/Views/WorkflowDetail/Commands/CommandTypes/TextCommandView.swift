import Inject
import SwiftUI

struct TextCommandView: View {
  let kind: CommandViewModel.Kind.TextModel.Kind
  let metaData: CommandViewModel.MetaData
  let iconSize: CGSize

  var body: some View {
    switch kind {
    case .type(let model):
      TypeCommandView(metaData, model: model, iconSize: iconSize)
    }
  }
}
