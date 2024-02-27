enum AppScene {
  case permissions
  case mainWindow
  case addGroup
  case addCommand(DetailViewModel.ID)
  case editGroup(GroupViewModel.ID)
}
