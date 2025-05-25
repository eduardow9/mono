import SwiftUI

// Adicionar notificações para markdown invisível
extension Notification.Name {
    // Notificações para comandos de markdown invisível
    static let toggleMarkdownToolbar = Notification.Name("toggleMarkdownToolbar")
    static let applyMarkdownBold = Notification.Name("applyMarkdownBold")
    static let applyMarkdownItalic = Notification.Name("applyMarkdownItalic")
    static let applyMarkdownH1 = Notification.Name("applyMarkdownH1")
    static let applyMarkdownH2 = Notification.Name("applyMarkdownH2")
    static let applyMarkdownH3 = Notification.Name("applyMarkdownH3")
    static let applyMarkdownBulletList = Notification.Name("applyMarkdownBulletList")
    static let applyMarkdownNumberedList = Notification.Name("applyMarkdownNumberedList")
    static let applyMarkdownLink = Notification.Name("applyMarkdownLink")
}
