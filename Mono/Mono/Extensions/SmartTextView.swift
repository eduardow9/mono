import SwiftUI
import AppKit

// Adicionar atributo personalizado para hashtags
private struct HashtagAttributeKey {
    static let name = NSAttributedString.Key("hashtag")
}

// Adicionar extensão para NSAttributedString.Key
private extension NSAttributedString.Key {
    static let hashtagAttribute = HashtagAttributeKey.name
}

// Extensão para centralizar elementos verticalmente
extension NSView {
    func centerY() {
        if let superview = self.superview {
            let superviewHeight = superview.bounds.height
            let viewHeight = self.frame.height
            let y = (superviewHeight - viewHeight) / 2
            self.frame.origin.y = y
        }
    }
}

class SmartTextView: NSTextView, NSTextViewDelegate {
    let markerColor = NSColor(calibratedRed: 0.95, green: 0.6, blue: 0.1, alpha: 1.0)
    let defaultFont = NSFont.systemFont(ofSize: 16)
    let markerDigitFont = NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
    private var textStorageDelegate: SmartTextViewDelegate?
    
    // Adicione esta propriedade para a busca no editor
    var editorSearchController: EditorSearchController?
    
    // Função helper para criar os atributos de digitação padrão
    private func defaultTypingAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6  // Ajuste este valor para controlar o espaçamento entre linhas
        
        return [
            .font: defaultFont,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    class SmartTextViewDelegate: NSObject, NSTextStorageDelegate {
        weak var textView: SmartTextView?
        
        init(textView: SmartTextView) {
            self.textView = textView
            super.init()
        }
        
        func textStorage(_ textStorage: NSTextStorage,
                         didProcessEditing editedMask: NSTextStorageEditActions,
                         range editedRange: NSRange,
                         changeInLength delta: Int) {
            guard let textView = textView, editedMask.contains(.editedCharacters) else { return }
            
            let string = textStorage.string as NSString
            let paraRange = string.paragraphRange(for: editedRange)
            let paraString = string.substring(with: paraRange)
            
            if let bulletRange = paraString.range(of: "• ", options: .literal) {
                let bulletIndex = paraString.distance(from: paraString.startIndex, to: bulletRange.lowerBound)
                if bulletIndex >= 0 {
                    let absoluteBulletRange = NSRange(location: paraRange.location + bulletIndex, length: 1)
                    textStorage.addAttribute(.foregroundColor, value: textView.markerColor, range: absoluteBulletRange)
                }
            }
            
            if let dashRange = paraString.range(of: "– ", options: .literal) {
                let dashIndex = paraString.distance(from: paraString.startIndex, to: dashRange.lowerBound)
                if dashIndex >= 0 {
                    let absoluteDashRange = NSRange(location: paraRange.location + dashIndex, length: 1)
                    textStorage.addAttribute(.foregroundColor, value: textView.markerColor, range: absoluteDashRange)
                }
            }
            
            if let match = paraString.range(of: #"^(\s*)\d+\."#, options: .regularExpression) {
                let matchString = String(paraString[match])
                if let numRange = matchString.range(of: #"\d+\."#, options: .regularExpression) {
                    let numIndex = paraString.distance(from: paraString.startIndex, to: match.lowerBound)
                                + matchString.distance(from: matchString.startIndex, to: numRange.lowerBound)
                    let numLength = matchString[numRange].count
                    let absoluteNumRange = NSRange(location: paraRange.location + numIndex, length: numLength)
                    textStorage.addAttribute(.foregroundColor, value: textView.markerColor, range: absoluteNumRange)
                }
            }
        }
    }
    
    // Funções de formatação
    func toggleBold() {
        toggleTrait(.bold)
        // Notificar alteração para salvar formatação
        self.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))
    }

    func toggleItalic() {
        toggleTrait(.italic)
        // Notificar alteração para salvar formatação
        self.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))
    }

    func toggleUnderline() {
        guard let range = selectedRange() as NSRange? else { return }
        let currentAttr = textStorage?.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
        let newValue = (currentAttr == 0) ? NSUnderlineStyle.single.rawValue : 0
        textStorage?.addAttribute(.underlineStyle, value: newValue, range: range)
        // Notificar alteração para salvar formatação
        self.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))
    }
    
    private func toggleTrait(_ trait: NSFontDescriptor.SymbolicTraits) {
        guard let range = selectedRange() as NSRange?, range.length > 0 else { return }
        guard let currentFont = textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont else { return }
        
        var traits = currentFont.fontDescriptor.symbolicTraits
        if traits.contains(trait) {
            traits.remove(trait)
        } else {
            traits.insert(trait)
        }
        
        let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traits)
        if let newFont = NSFont(descriptor: descriptor, size: currentFont.pointSize) {
            textStorage?.addAttribute(.font, value: newFont, range: range)
            // Notificar alteração para salvar formatação
            self.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))
        }
    }
    
    override func deleteBackward(_ sender: Any?) {
        let range = self.selectedRange()
        guard range.length == 0 else {
            super.deleteBackward(sender)
            return
        }
        
        let fullText = self.string as NSString
        let lineRange = fullText.lineRange(for: NSRange(location: range.location, length: 0))
        let currentLine = fullText.substring(with: lineRange)
        
        if currentLine.trimmingCharacters(in: .whitespacesAndNewlines) == "•"
            || currentLine.trimmingCharacters(in: .whitespacesAndNewlines) == "–"
            || currentLine.range(of: #"^\s*\d+\.\s*$"#, options: .regularExpression) != nil {
            self.textStorage?.deleteCharacters(in: lineRange)
            return
        }
        
        super.deleteBackward(sender)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.font = defaultFont
        self.typingAttributes = defaultTypingAttributes()
        self.textColor = NSColor.labelColor
        self.delegate = self
        
        // Inicializar o controlador de busca do editor
        editorSearchController = EditorSearchController(textView: self)
    }
    
    // Nova função pública para acesso externo
    public func applyStylesToFormattedText() {
        formatFormattedText()
        detectAndFormatHashtags()
    }
    
    // Função privada para formatar o texto
    private func formatFormattedText() {
        guard let textStorage = self.textStorage else { return }
        
        let nsString = textStorage.string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        // Formatação para marcadores
        nsString.enumerateSubstrings(in: fullRange, options: .byParagraphs) { line, paragraphRange, _, _ in
            guard let line = line else { return }
            
            // Bullets
            if line.hasPrefix("  • ") {
                let bulletRange = NSRange(location: paragraphRange.location + 2, length: 1)
                textStorage.addAttribute(.foregroundColor, value: self.markerColor, range: bulletRange)
            }
            
            // Traços
            if line.hasPrefix("  – ") {
                let dashRange = NSRange(location: paragraphRange.location + 2, length: 1)
                textStorage.addAttribute(.foregroundColor, value: self.markerColor, range: dashRange)
            }
            
            // Listas numeradas
            if let match = line.range(of: #"^  \d+\."#, options: .regularExpression) {
                let nsrange = NSRange(match, in: line)
                textStorage.addAttribute(.foregroundColor, value: self.markerColor,
                                      range: NSRange(location: paragraphRange.location + nsrange.location,
                                                    length: nsrange.length))
            }
        }
    }
    
    // Detecta e formata hashtags no texto
    private func detectAndFormatHashtags() {
        guard let textStorage = self.textStorage else { return }
        
        // Remover formatação existente de hashtags para evitar duplicações
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.removeAttribute(.hashtagAttribute, range: fullRange)
        
        let nsString = textStorage.string as NSString
        
        // Expressão regular melhorada para identificar hashtags corretamente
        // Hashtag deve começar com # seguido por letras/números, e terminar com espaço ou fim de linha
        let hashtagPattern = "#[a-zA-Z0-9_]+(?=\\s|$)"
        
        do {
            let regex = try NSRegularExpression(pattern: hashtagPattern, options: [])
            let matches = regex.matches(in: nsString as String, options: [], range: fullRange)
            
            // Conjunto para rastrear hashtags únicas e evitar duplicações
            var detectedTags = Set<String>()
            
            for match in matches {
                // Usar uma cor consistente para as hashtags (laranja)
                textStorage.addAttribute(.foregroundColor, value: markerColor, range: match.range)
                
                // Armazenar o atributo de tipo para a hashtag
                textStorage.addAttribute(.hashtagAttribute, value: true, range: match.range)
                
                // Extrair o texto da hashtag
                if let substring = nsString.substring(with: match.range) as String? {
                    // Adicionar ao conjunto para evitar duplicação
                    detectedTags.insert(substring)
                }
            }
            
            // Notificar sobre as hashtags detectadas
            for tag in detectedTags {
                notifyHashtagDetected(tag)
            }
        } catch {
            print("Erro ao processar hashtags: \(error)")
        }
    }

    // Melhorar o tratamento de eventos de hashtag
    private func notifyHashtagDetected(_ hashtag: String) {
        // Remover o caractere # para obter o nome real da tag
        let tagName = hashtag.hasPrefix("#") ? String(hashtag.dropFirst()) : hashtag
        
        // Ignorar tags vazias
        guard !tagName.isEmpty else { return }
        
        // Enviar notificação para o sistema criar ou atualizar a tag
        NotificationCenter.default.post(
            name: .hashtagDetected,
            object: nil,
            userInfo: ["tagName": tagName]
        )
    }
    
    override func didChangeText() {
        super.didChangeText()
        
        // Garantir que estilos sejam reaplicados
        applyStylesToFormattedText()
        
        // Processar markdown invisível (adicionar esta linha)
        processMarkdownInvisible()
    }



    
    // Versão modificada do método keyDown para suportar a busca no editor
    override func keyDown(with event: NSEvent) {
        // CMD+F para busca no editor
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "f" {
            // Garantir que o editorSearchController está inicializado
            if editorSearchController == nil {
                editorSearchController = EditorSearchController(textView: self)
            }
            
            // Mostrar a barra de busca
            editorSearchController?.showSearchBar()
            return
        }
        
        // ESC para sair da busca no editor ou retornar à lista
        if event.keyCode == 53 {
            if editorSearchController?.isActive == true {
                editorSearchController?.hideSearchBar()
                return
            }
            
            // Se não estiver em busca, ESC retorna à lista de notas
            if let window = self.window {
                window.makeFirstResponder(nil)
                return
            }
        }
        
        // Enter para navegar para o próximo resultado na busca do editor
        if event.keyCode == 36 {
            // Se a busca está ativa e há resultados, navegar para o próximo
            if editorSearchController?.isActive == true && (editorSearchController?.searchResults.count ?? 0) > 0 {
                editorSearchController?.nextMatch()
                return
            }
            
            // Verifica se estamos em uma janela de busca do sistema
            if let window = self.window, window.firstResponder is NSSearchField {
                editorSearchController?.nextMatch()
                return
            }
            
            // Processamento normal do Enter para o editor
            let range = self.selectedRange()
            let fullText = self.string as NSString
            let currentLine = fullText.substring(with: fullText.lineRange(for: NSRange(location: range.location, length: 0)))
            
            if currentLine.trimmingCharacters(in: .whitespacesAndNewlines) == "•"
                || currentLine.trimmingCharacters(in: .whitespacesAndNewlines) == "–"
                || currentLine.range(of: #"^\s*\d+\.\s*$"#, options: .regularExpression) != nil {
                let lineRange = fullText.lineRange(for: NSRange(location: range.location, length: 0))
                self.textStorage?.deleteCharacters(in: lineRange)
                self.insertText("\n", replacementRange: self.selectedRange())
                return
            }
            
            let text = fullText.substring(to: range.location)
            if let lastLine = text.components(separatedBy: .newlines).last {
                if lastLine.hasPrefix("  • ") {
                    let bulletText = NSMutableAttributedString()
                    
                    let initialPart = NSAttributedString(string: "\n  ", attributes: [.font: defaultFont])
                    bulletText.append(initialPart)
                    
                    let bulletPart = NSAttributedString(string: "•", attributes: [
                        .font: defaultFont,
                        .foregroundColor: markerColor
                    ])
                    bulletText.append(bulletPart)
                    
                    let spacePart = NSAttributedString(string: " ", attributes: [.font: defaultFont])
                    bulletText.append(spacePart)
                    
                    self.textStorage?.replaceCharacters(in: self.selectedRange(), with: bulletText)
                    self.setSelectedRange(NSMakeRange(self.selectedRange().location + bulletText.length, 0))
                    self.typingAttributes = defaultTypingAttributes()
                    return
                }
                
                if lastLine.hasPrefix("  – ") {
                    let dashText = NSMutableAttributedString()
                    
                    let initialPart = NSAttributedString(string: "\n  ", attributes: [.font: defaultFont])
                    dashText.append(initialPart)
                    
                    let dashPart = NSAttributedString(string: "–", attributes: [
                        .font: defaultFont,
                        .foregroundColor: markerColor
                    ])
                    dashText.append(dashPart)
                    
                    let spacePart = NSAttributedString(string: " ", attributes: [.font: defaultFont])
                    dashText.append(spacePart)
                    
                    self.textStorage?.replaceCharacters(in: self.selectedRange(), with: dashText)
                    self.setSelectedRange(NSMakeRange(self.selectedRange().location + dashText.length, 0))
                    self.typingAttributes = defaultTypingAttributes()
                    return
                }
                
                if let match = lastLine.range(of: #"^  (\d+)\. "#, options: .regularExpression) {
                    let numberStr = lastLine[match]
                        .replacingOccurrences(of: "  ", with: "")
                        .replacingOccurrences(of: ". ", with: "")
                    if let number = Int(numberStr) {
                        let nextNumber = number + 1
                        let numberText = NSMutableAttributedString()
                        
                        let initialPart = NSAttributedString(string: "\n  ", attributes: [.font: defaultFont])
                        numberText.append(initialPart)
                        
                        let numberPart = NSAttributedString(string: "\(nextNumber).", attributes: [
                            .font: defaultFont,
                            .foregroundColor: markerColor
                        ])
                        numberText.append(numberPart)
                        
                        let spacePart = NSAttributedString(string: " ", attributes: [.font: defaultFont])
                        numberText.append(spacePart)
                        
                        self.textStorage?.replaceCharacters(in: self.selectedRange(), with: numberText)
                        self.setSelectedRange(NSMakeRange(self.selectedRange().location + numberText.length, 0))
                        self.typingAttributes = defaultTypingAttributes()
                        return
                    }
                }
            }
        }
        
        // Shift+Enter para navegar para o resultado anterior na busca do editor
        if event.keyCode == 36 &&
           event.modifierFlags.contains(.shift) &&
           editorSearchController?.isActive == true &&
           editorSearchController?.searchResults.count ?? 0 > 0 {
            editorSearchController?.previousMatch()
            return
        }
        
        // Atalho Command + A → selecionar todo o texto
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
           event.charactersIgnoringModifiers == "a" {
            self.selectAll(nil)
            return
        }
        
        super.keyDown(with: event)
    }

    // Garante que ⌘A (Command + A) selecione todo o texto desta view,
    // impedindo que a combinação suba para a lista de notas.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
           event.charactersIgnoringModifiers == "a" {
            self.selectAll(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
    
    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        if let string = insertString as? String, string == "\n" {
            let range = self.selectedRange()
            let fullText = self.string as NSString
            let currentLine = fullText.substring(with: fullText.lineRange(for: NSRange(location: range.location, length: 0)))
            
            if currentLine == "  • "
                || currentLine == "  – "
                || currentLine.range(of: #"^  \d+\. $"#, options: .regularExpression) != nil {
                self.textStorage?.deleteCharacters(in: fullText.lineRange(for: NSRange(location: range.location, length: 0)))
                return
            }
            
            let before = fullText.substring(to: range.location)
            if let lastLine = before.components(separatedBy: .newlines).last {
                if lastLine.hasPrefix("  • ") {
                    let bulletText = NSMutableAttributedString()
                    
                    let initialPart = NSAttributedString(string: "\n  ", attributes: [.font: defaultFont])
                    bulletText.append(initialPart)
                    
                    let bulletPart = NSAttributedString(string: "•", attributes: [
                        .font: defaultFont,
                        .foregroundColor: markerColor
                    ])
                    bulletText.append(bulletPart)
                    
                    let spacePart = NSAttributedString(string: " ", attributes: [.font: defaultFont])
                    bulletText.append(spacePart)
                    
                    self.textStorage?.replaceCharacters(in: replacementRange, with: bulletText)
                    self.setSelectedRange(NSMakeRange(replacementRange.location + bulletText.length, 0))
                    self.typingAttributes = defaultTypingAttributes()
                    return
                }
                
                if lastLine.hasPrefix("  – ") {
                    let dashText = NSMutableAttributedString()
                    
                    let initialPart = NSAttributedString(string: "\n  ", attributes: [.font: defaultFont])
                    dashText.append(initialPart)
                    
                    let dashPart = NSAttributedString(string: "–", attributes: [
                        .font: defaultFont,
                        .foregroundColor: markerColor
                    ])
                    dashText.append(dashPart)
                    
                    let spacePart = NSAttributedString(string: " ", attributes: [.font: defaultFont])
                    dashText.append(spacePart)
                    
                    self.textStorage?.replaceCharacters(in: replacementRange, with: dashText)
                    self.setSelectedRange(NSMakeRange(replacementRange.location + dashText.length, 0))
                    self.typingAttributes = defaultTypingAttributes()
                    return
                }
                
                if let match = lastLine.range(of: #"^  (\d+)\. "#, options: .regularExpression) {
                    let numberStr = lastLine[match]
                        .replacingOccurrences(of: "  ", with: "")
                        .replacingOccurrences(of: ". ", with: "")
                    if let number = Int(numberStr) {
                        let nextNumber = number + 1
                        let numberText = NSMutableAttributedString()
                        
                        let initialPart = NSAttributedString(string: "\n  ", attributes: [.font: defaultFont])
                        numberText.append(initialPart)
                        
                        let numberPart = NSAttributedString(string: "\(nextNumber).", attributes: [
                            .font: markerDigitFont,
                            .foregroundColor: markerColor
                        ])
                        numberText.append(numberPart)
                        
                        let spacePart = NSAttributedString(string: " ", attributes: [.font: defaultFont])
                        numberText.append(spacePart)
                        
                        self.textStorage?.replaceCharacters(in: replacementRange, with: numberText)
                        self.setSelectedRange(NSMakeRange(replacementRange.location + numberText.length, 0))
                        self.typingAttributes = defaultTypingAttributes()
                        return
                    }
                }
            }
        }
        
        if let string = insertString as? String, string == " " {
            let range = self.selectedRange()
            let fullText = self.string as NSString
            let before = fullText.substring(to: range.location)
            
            if let lastLine = before.components(separatedBy: .newlines).last {
                // Aciona bullet se o gatilho for * ou . no início da linha (apenas espaços antes)
                if lastLine.range(of: #"^\s*[\*\.]$"#, options: .regularExpression) != nil {
                    let replacement = NSRange(location: range.location - 1, length: 1)
                    let bulletText = NSMutableAttributedString()
                    
                    let initialPart = NSAttributedString(string: "  ", attributes: [.font: defaultFont])
                    bulletText.append(initialPart)
                    
                    let bulletPart = NSAttributedString(string: "•", attributes: [
                        .font: defaultFont,
                        .foregroundColor: markerColor
                    ])
                    bulletText.append(bulletPart)
                    
                    let spacePart = NSAttributedString(string: " ", attributes: [.font: defaultFont])
                    bulletText.append(spacePart)
                    
                    self.textStorage?.replaceCharacters(in: replacement, with: bulletText)
                    self.setSelectedRange(NSMakeRange(replacement.location + bulletText.length, 0))
                    self.typingAttributes = defaultTypingAttributes()
                    return
                } else if lastLine.range(of: #"^\s*-$"#, options: .regularExpression) != nil {
                    let replacement = NSRange(location: range.location - 1, length: 1)
                    let dashText = NSMutableAttributedString()
                    
                    let initialPart = NSAttributedString(string: "  ", attributes: [.font: defaultFont])
                    dashText.append(initialPart)
                    
                    let dashPart = NSAttributedString(string: "–", attributes: [
                        .font: defaultFont,
                        .foregroundColor: markerColor
                    ])
                    dashText.append(dashPart)
                    
                    let spacePart = NSAttributedString(string: " ", attributes: [.font: defaultFont])
                    dashText.append(spacePart)
                    
                    self.textStorage?.replaceCharacters(in: replacement, with: dashText)
                    self.setSelectedRange(NSMakeRange(replacement.location + dashText.length, 0))
                    self.typingAttributes = defaultTypingAttributes()
                    return
                } else if lastLine.range(of: #"^\s*\d+\.$"#, options: .regularExpression) != nil {
                    let replacement = NSRange(location: range.location - lastLine.count, length: lastLine.count)
                    let numberText = NSMutableAttributedString()
                    
                    let initialPart = NSAttributedString(string: "  ", attributes: [.font: defaultFont])
                    numberText.append(initialPart)
                    
                    let numberPart = NSAttributedString(string: "1.", attributes: [
                        .font: markerDigitFont,
                        .foregroundColor: markerColor
                    ])
                    numberText.append(numberPart)
                    
                    let spacePart = NSAttributedString(string: " ", attributes: [.font: defaultFont])
                    numberText.append(spacePart)
                    
                    self.textStorage?.replaceCharacters(in: replacement, with: numberText)
                    self.setSelectedRange(NSMakeRange(replacement.location + numberText.length, 0))
                    self.typingAttributes = defaultTypingAttributes()
                    return
                }
            }
        }
        
        // Se o usuário digitou #, verificar se há hashtags para formatar
        if let string = insertString as? String, string.contains("#") {
            super.insertText(insertString, replacementRange: replacementRange)
            detectAndFormatHashtags()
            return
        }
        
        self.typingAttributes = defaultTypingAttributes()
        self.textColor = NSColor.labelColor
        super.insertText(insertString, replacementRange: replacementRange)
    }
    
    func applyHeader(level: Int) {
        guard let range = selectedRange() as NSRange? else { return }
        
        let size: CGFloat
        switch level {
        case 1:
            size = 28
        case 2:
            size = 24
        case 3:
            size = 18
        default:
            size = 16
        }
        
        let font = NSFont(name: "Charter-Bold", size: size)
                    ?? NSFont.systemFont(ofSize: size, weight: .bold)
        textStorage?.addAttribute(.font, value: font, range: range)
    }
    
    func applyBullet() {
        insertText("  • ", replacementRange: selectedRange())
    }
    
    func applyNumbered() {
        insertText("  1. ", replacementRange: selectedRange())
    }
    
    // Override paste para colar apenas texto simples
    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        
        // Tentar obter texto simples
        if let plainText = pasteboard.string(forType: .string) {
            // Aplicar os atributos padrão ao texto colado
            let attributedText = NSAttributedString(string: plainText, attributes: defaultTypingAttributes())
            
            // Inserir o texto com formatação padrão
            let range = self.selectedRange()
            self.textStorage?.replaceCharacters(in: range, with: attributedText)
            
            // Mover o cursor para o final do texto colado
            self.setSelectedRange(NSRange(location: range.location + plainText.count, length: 0))
            
            // Aplicar estilos de formatação se necessário
            self.applyStylesToFormattedText()
            
            // Notificar mudança
            self.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))
        } else {
            // Se não houver texto simples, usar o comportamento padrão
            super.paste(sender)
        }
    }
    
    // Override para Cmd+Shift+V (colar sem formatação)
    override func pasteAsPlainText(_ sender: Any?) {
        // Mesmo comportamento que o paste normal, já que sempre colamos sem formatação
        self.paste(sender)
    }
}

// Extension para funções de edição específicas
extension SmartTextView {
    func textView(_ textView: NSTextView,
                  shouldChangeTextIn affectedCharRange: NSRange,
                  replacementString: String?) -> Bool {
        if replacementString != nil,
           affectedCharRange.length > 0 {
            let fullText = self.string as NSString
            let paraRange = fullText.paragraphRange(for: affectedCharRange)
            let lineStart = paraRange.location
            
            if affectedCharRange.location < lineStart + 4 {
                let line = fullText.substring(with: paraRange)
                
                if line.hasPrefix("  • ")
                    || line.hasPrefix("  – ")
                    || line.range(of: #"^  \d+\. "#, options: .regularExpression) != nil {
                    if affectedCharRange.location < lineStart + 4
                       && (affectedCharRange.location + affectedCharRange.length > lineStart) {
                        return false
                    }
                }
            }
        }
        return true
    }
}

// Override para interceptar o comando de colar e forçar texto simples
extension SmartTextView {
    // Validar os comandos do menu
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        // Se for o comando de colar, sempre permitir
        if item.action == #selector(paste(_:)) {
            return NSPasteboard.general.canReadObject(forClasses: [NSString.self], options: nil)
        }
        
        return super.validateUserInterfaceItem(item)
    }
}
