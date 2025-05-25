import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// Arquivo específico para registrar transformadores
// Este arquivo deve ser incluído em todos os targets

// Transformador para NSAttributedString
@objc(NSAttributedStringTransformer)
final class NSAttributedStringTransformer: NSSecureUnarchiveFromDataTransformer {
    static let transformerName = NSValueTransformerName("NSAttributedStringTransformer")
    
    override static var allowedTopLevelClasses: [AnyClass] {
        return [NSAttributedString.self, NSMutableAttributedString.self]
    }
}

// Função global para registrar todos os transformadores necessários
func registerAllValueTransformers() {
    let transformer = NSAttributedStringTransformer()
    ValueTransformer.setValueTransformer(
        transformer,
        forName: NSAttributedStringTransformer.transformerName
    )
}
