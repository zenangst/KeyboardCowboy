enum LocalFocus<Element>: Hashable where Element: Identifiable {
  case element(Element.ID)
}
