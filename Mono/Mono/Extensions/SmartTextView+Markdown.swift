// Extensão para SmartTextView para implementar o Markdown Invisível
import Foundation
import AppKit

// Extensão que adiciona funcionalidade de Markdown Invisível ao SmartTextView
extension SmartTextView {
    
    // Método público para processar markdown no texto
    // Deve ser chamado após applyStylesToFormattedText() no didChangeText()
    func processMarkdownInvisible() {
        guard let textStorage = self.textStorage, textStorage.length > 0 else { return }
        
        // Preservar a seleção atual
        let selectedRange = self.selectedRange()
        
        // Processar markdown
        processHeadingsMarkdown(in: textStorage)  // Processar títulos primeiro para evitar conflitos
        processBoldMarkdown(in: textStorage)
        processItalicMarkdown(in: textStorage)
        processLinkMarkdown(in: textStorage)
        
        // Restaurar a seleção
        if selectedRange.location <= textStorage.length {
            self.setSelectedRange(selectedRange)
        }
    }
    
    // Processar títulos: # Título, ## Título, ### Título
    private func processHeadingsMarkdown(in textStorage: NSTextStorage) {
        let text = textStorage.string
        
        let headingPatterns = [
            ("^(# )(.*)$", 24.0, "# "),
            ("^(## )(.*)$", 20.0, "## "),
            ("^(### )(.*)$", 18.0, "### ")
        ]
        
        for (pattern, fontSize, prefix) in headingPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
                let nsString = text as NSString
                let fullRange = NSRange(location: 0, length: nsString.length)
                
                let matches = regex.matches(in: text, options: [], range: fullRange)
                
                for match in matches {
                    if match.numberOfRanges < 3 { continue }
                    
                    let fullMatchRange = match.range
                    let prefixRange = match.range(at: 1)
                    let contentRange = match.range(at: 2)
                    
                    if fullMatchRange.location == NSNotFound || prefixRange.location == NSNotFound { continue }
                    
                    let headingFont = NSFont.boldSystemFont(ofSize: CGFloat(fontSize))
                    
                    if contentRange.length > 0 && contentRange.location + contentRange.length <= textStorage.length {
                        textStorage.addAttribute(.font, value: headingFont, range: contentRange)
                        textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: contentRange)
                    } else {
                        let cursorPosition = prefixRange.location + prefixRange.length
                        if cursorPosition < textStorage.length {
                            self.typingAttributes[.font] = headingFont
                            self.typingAttributes[.foregroundColor] = NSColor.labelColor
                        }
                    }
                    
                    // Calcular a largura real do prefixo
                    let prefixAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
                    let prefixSize = (prefix as NSString).size(withAttributes: prefixAttributes)
                    let prefixWidth = prefixSize.width
                    
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.paragraphSpacingBefore = 12.0
                    paragraphStyle.paragraphSpacing = 8.0
                    paragraphStyle.lineSpacing = 6.0
                    paragraphStyle.headIndent = 0
                    paragraphStyle.firstLineHeadIndent = -prefixWidth
                    
                    textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullMatchRange)
                    textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: prefixRange)
                    textStorage.addAttribute(.kern, value: -prefixWidth, range: prefixRange)
                }
            } catch {
                print("Erro ao processar títulos: \(error)")
            }
        }
    }
    
    // Processar negrito: **texto** ou __texto__
    private func processBoldMarkdown(in textStorage: NSTextStorage) {
        let text = textStorage.string
        let patterns = ["\\*\\*(.*?)\\*\\*", "__(.*?)__"]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let nsString = text as NSString
                let fullRange = NSRange(location: 0, length: nsString.length)
                
                // Encontrar todas as correspondências
                let matches = regex.matches(in: text, options: [], range: fullRange)
                
                for match in matches {
                    if match.numberOfRanges < 2 { continue }
                    
                    let fullMatchRange = match.range
                    let innerContentRange = match.range(at: 1)
                    
                    // Verificar se os ranges são válidos
                    if fullMatchRange.location == NSNotFound || innerContentRange.location == NSNotFound { continue }
                    
                    // Extrair o texto dentro dos delimitadores
                    let content = nsString.substring(with: innerContentRange)
                    
                    // Aplicar formatação de negrito sem alterar outros atributos
                    let boldRange = NSRange(location: fullMatchRange.location + 2, length: content.count)
                    if boldRange.location + boldRange.length <= textStorage.length {
                        // Obter a fonte atual ou usar a padrão
                        let currentFont = textStorage.attribute(.font, at: boldRange.location, effectiveRange: nil) as? NSFont ?? self.defaultFont
                        
                        // Criar fonte em negrito mantendo o tamanho atual
                        let boldDescriptor = currentFont.fontDescriptor.withSymbolicTraits(.bold)
                        if let boldFont = NSFont(descriptor: boldDescriptor, size: currentFont.pointSize) {
                            textStorage.addAttribute(.font, value: boldFont, range: boldRange)
                        }
                        
                        // Ocultar os delimitadores markdown
                        let prefixRange = NSRange(location: fullMatchRange.location, length: 2)
                        let suffixRange = NSRange(location: fullMatchRange.location + fullMatchRange.length - 2, length: 2)
                        
                        // Tornar os delimitadores invisíveis usando cor transparente
                        textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: prefixRange)
                        textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: suffixRange)
                    }
                }
            } catch {
                print("Erro ao processar negrito: \(error)")
            }
        }
    }
    
    // Processar itálico: *texto* ou _texto_
    private func processItalicMarkdown(in textStorage: NSTextStorage) {
        let text = textStorage.string
        
        // Padrões para itálico, evitando conflito com negrito
        // Usamos lookahead/lookbehind negativos para evitar conflitos com negrito
        let patterns = ["(?<![\\*])(\\*)((?!\\*).+?)(\\*)(?![\\*])", "(?<![_])(_)((?!_).+?)(_)(?![_])"]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let nsString = text as NSString
                let fullRange = NSRange(location: 0, length: nsString.length)
                
                // Encontrar todas as correspondências
                let matches = regex.matches(in: text, options: [], range: fullRange)
                
                for match in matches {
                    if match.numberOfRanges < 4 { continue }
                    
                    let fullMatchRange = match.range
                    let prefixRange = match.range(at: 1)
                    let contentRange = match.range(at: 2)
                    let suffixRange = match.range(at: 3)
                    
                    // Verificar se os ranges são válidos
                    if fullMatchRange.location == NSNotFound || contentRange.location == NSNotFound { continue }
                    
                    // Aplicar formatação de itálico sem alterar outros atributos
                    if contentRange.location + contentRange.length <= textStorage.length {
                        // Obter a fonte atual ou usar a padrão
                        let currentFont = textStorage.attribute(.font, at: contentRange.location, effectiveRange: nil) as? NSFont ?? self.defaultFont
                        
                        // Criar fonte em itálico mantendo o tamanho atual
                        let italicDescriptor = currentFont.fontDescriptor.withSymbolicTraits(.italic)
                        if let italicFont = NSFont(descriptor: italicDescriptor, size: currentFont.pointSize) {
                            textStorage.addAttribute(.font, value: italicFont, range: contentRange)
                        }
                        
                        // Tornar os delimitadores invisíveis usando cor transparente
                        textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: prefixRange)
                        textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: suffixRange)
                    }
                }
            } catch {
                print("Erro ao processar itálico: \(error)")
            }
        }
    }
    
    // Processar links: [texto](url)
    private func processLinkMarkdown(in textStorage: NSTextStorage) {
        let text = textStorage.string
        
        // Padrão para links
        let pattern = "\\[(.*?)\\]\\((.*?)\\)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let fullRange = NSRange(location: 0, length: nsString.length)
            
            // Encontrar todas as correspondências
            let matches = regex.matches(in: text, options: [], range: fullRange)
            
            for match in matches {
                if match.numberOfRanges < 3 { continue }
                
                let fullMatchRange = match.range
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                
                // Verificar se os ranges são válidos
                if fullMatchRange.location == NSNotFound || textRange.location == NSNotFound || urlRange.location == NSNotFound { continue }
                
                // Extrair o texto e a URL
                _ = nsString.substring(with: textRange)
                let linkURLString = nsString.substring(with: urlRange)
                
                // Aplicar formatação de link sem alterar outros atributos
                if textRange.location + textRange.length <= textStorage.length {
                    // Criar URL a partir da string
                    var urlString = linkURLString
                    if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                        urlString = "https://" + urlString
                    }
                    
                    // Aplicar atributos de link (apenas visual, sem funcionalidade de clique por enquanto)
                    textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: textRange)
                    textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                    
                    // Ocultar os delimitadores markdown
                    // Prefixo: [
                    let prefixRange = NSRange(location: fullMatchRange.location, length: 1)
                    // Meio: ]
                    let middleStartLocation = textRange.location + textRange.length
                    let middleRange = NSRange(location: middleStartLocation, length: 1)
                    // Parênteses e URL: (url)
                    let urlPrefixRange = NSRange(location: middleStartLocation + 1, length: 1)
                    let urlSuffixRange = NSRange(location: fullMatchRange.location + fullMatchRange.length - 1, length: 1)
                    
                    // Tornar os delimitadores invisíveis usando cor transparente
                    textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: prefixRange)
                    textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: middleRange)
                    textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: urlPrefixRange)
                    textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: urlRange)
                    textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: urlSuffixRange)
                }
            }
        } catch {
            print("Erro ao processar links: \(error)")
        }
    }
}

// IMPORTANTE: Para usar esta extensão, adicione a seguinte linha ao método didChangeText() no SmartTextView.swift:
/*
override func didChangeText() {
    super.didChangeText()
    
    // Garantir que estilos sejam reaplicados
    applyStylesToFormattedText()
    
    // Processar markdown invisível (adicionar esta linha)
    processMarkdownInvisible()
}
*/
