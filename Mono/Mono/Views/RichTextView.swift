import SwiftUI
import AppKit

struct RichTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    var colorScheme: ColorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = SmartTextView()
        textViewGlobal = textView
        textView.backgroundColor = NSColor(named: "EditorBackground") ?? .black
        scrollView.backgroundColor = NSColor(named: "EditorBackground") ?? .black
        scrollView.drawsBackground = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = true
        textView.usesFontPanel = false
        textView.importsGraphics = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 40, height: 40)
        textView.font = NSFont.systemFont(ofSize: 16)
        textView.textColor = NSColor(named: "TextPrimary") ?? NSColor.labelColor
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor(named: "TextPrimary") ?? NSColor.labelColor
        ]
        
        if attributedText.string.isEmpty && !text.isEmpty {
            textView.string = text
        } else {
            textView.textStorage?.setAttributedString(attributedText)
        }
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        textView.delegate = context.coordinator
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? SmartTextView else { return }
        
        // Melhorar a lógica para preservar a formatação
        if textView.string != text || textView.textStorage?.string != attributedText.string {
            let selectedRanges = textView.selectedRanges
            
            // Usar sempre o texto atribuído para preservar a formatação
            textView.textStorage?.setAttributedString(attributedText)
            
            // Restaurar a seleção
            if !selectedRanges.isEmpty, let firstRange = selectedRanges.first?.rangeValue,
               firstRange.location < textView.string.count {
                textView.selectedRanges = selectedRanges
            }
            
            // Aplicar estilos adicionais
            textView.applyStylesToFormattedText()
        }
    }
    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        if let textView = nsView.documentView as? SmartTextView, textViewGlobal === textView {
            textViewGlobal = nil
        }
        
        NotificationCenter.default.removeObserver(coordinator)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: RichTextView
        weak var textView: NSTextView?

        init(parent: RichTextView) {
            self.parent = parent
            super.init()
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFocusEditor),
                name: .focusEditor,
                object: nil
            )
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Só atualiza se o texto realmente mudou
            if parent.text != textView.string {
                parent.text = textView.string
                
                if let attributedString = textView.textStorage?.copy() as? NSAttributedString {
                    parent.attributedText = attributedString
                }
            }
        }
        
        @objc func handleFocusEditor(_ notification: Notification) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let textView = self.textView else { return }
                textView.window?.makeFirstResponder(textView)
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
