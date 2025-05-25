import Foundation
import CoreData

extension NoteEntity {
    var formattedContent: NSAttributedString? {
        get {
            return attributedContent
        }
        set {
            attributedContent = newValue
            
            if let newValue = newValue {
                content = newValue.string
            } else {
                content = nil
            }
        }
    }
}
