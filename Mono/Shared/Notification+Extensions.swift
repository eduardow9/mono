import SwiftUI


extension Notification.Name {
    static let deleteNote = Notification.Name("deleteNote")
    static let focusEditor = Notification.Name("FocusOnEditor")
    static let hashtagDetected = Notification.Name("hashtagDetected")

    static let applyBold = Notification.Name("applyBold")
    static let applyItalic = Notification.Name("applyItalic")
    static let applyUnderline = Notification.Name("applyUnderline")
    static let applyH1 = Notification.Name("applyH1")
    static let applyH2 = Notification.Name("applyH2")
    static let applyH3 = Notification.Name("applyH3")
    static let applyBulletList = Notification.Name("applyBulletList")
    static let applyNumberedList = Notification.Name("applyNumberedList")
    static let doSearch = Notification.Name("doSearch")
    static let nextSearchResult = Notification.Name("nextSearchResult")
    static let previousSearchResult = Notification.Name("previousSearchResult")
    static let dismissSearch = Notification.Name("dismissSearch")
    static let toggleSidebar = Notification.Name("toggleSidebar")
}
