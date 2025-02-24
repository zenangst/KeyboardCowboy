protocol SystemRoutine {
  var application: UserSpace.Application { get }

  init(application: UserSpace.Application)

  func run(_ kind: SystemCommand.Kind)
  
  func run(_ kind: WindowFocusCommand.Kind)
}
