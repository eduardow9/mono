import SwiftUI
import Foundation
import LocalAuthentication

#if os(macOS)
var textViewGlobal: SmartTextView?
var isActivelyEditing = false
#endif

struct EditorView: View {
    @Binding var note: NoteEntity
    @State private var currentText: String = ""
    @State private var currentAttributedText: NSAttributedString?
    @State private var isUnlocked = false
    @State private var initialized = false
    @State private var lastNoteId: UUID?
    @EnvironmentObject var store: NotesStore
    @Environment(\.colorScheme) var colorScheme
    
    /// Atualiza nota, título, data e salva
    private func processChange(_ newValue: String) {
        // Verificar se a mudança é para a nota atual
        guard note.id == lastNoteId else { return }
        
        if note.content != newValue {
            note.content = newValue
            if let attrText = currentAttributedText {
                note.formattedContent = attrText
            }
            note.title = store.getTitleFromContent(newValue)
            note.dateModified = Date()
            
            // Forçar atualização da UI imediatamente
            store.objectWillChange.send()
            
            // Agendar promoção se necessário
            store.scheduleNotePromotionAfterEditing(note)
            
            // Salvar após um pequeno delay para evitar muitas escritas
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                try? self.store.context.save()
            }
        }
    }
    
    private func loadNoteContent() {
        if note.isLocked && !isUnlocked {
            currentText = ""
            currentAttributedText = NSAttributedString(string: "")
        } else {
            if let formattedContent = note.formattedContent {
                currentAttributedText = formattedContent
                currentText = formattedContent.string
            } else {
                currentText = note.content ?? ""
                currentAttributedText = NSAttributedString(string: currentText)
            }
        }
        lastNoteId = note.id
    }
    
    // Tornando o inicializador explicitamente público
    public init(note: Binding<NoteEntity>) {
        self._note = note
    }
    
    var body: some View {
        Group {
            
            if note.isLocked && !isUnlocked {
#if os(macOS)
                LockedNoteView(note: note, isUnlocked: $isUnlocked)
#else
                LockedNoteView_iOS(note: note, isUnlocked: $isUnlocked)
#endif
            }
            
            else {
                VStack(spacing: 0) {
#if os(macOS)
                    RichTextView(
                        text: $currentText,
                        attributedText: Binding(
                            get: { currentAttributedText ?? NSAttributedString(string: "") },
                            set: { newValue in
                                currentAttributedText = newValue
                                currentText = newValue.string
                            }
                        ),
                        colorScheme: colorScheme
                    )
                    .background(Color("EditorBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("BorderColor"), lineWidth: 1)
                    )
                    .onChange(of: currentText) { oldValue, newValue in
                        if oldValue != newValue && note.id == lastNoteId {
                            processChange(newValue)
                        }
                    }
                    .onTapGesture {
                        isActivelyEditing = true
                    }
#else
                    RichTextView_iOS(
                        text: $currentText,
                        attributedText: Binding(
                            get: { currentAttributedText ?? NSAttributedString(string: "") },
                            set: { newValue in
                                currentAttributedText = newValue
                                currentText = newValue.string
                            }
                        )
                    )
                    .onChange(of: currentText) { oldValue, newValue in
                        if oldValue != newValue && note.id == lastNoteId {
                            processChange(newValue)
                        }
                    }
#endif
                    
                }
            }
        }
        .onAppear {
            loadNoteContent()
            initialized = true
#if os(macOS)
            setupFormatObservers()
#endif
        }
        .onChange(of: note.id) { oldNoteId, newNoteId in
            // Cancelar qualquer promoção pendente
            store.cancelNotePromotion()
            
            // Salvar mudanças da nota anterior se houver
            if oldNoteId != newNoteId {
#if os(macOS)
                if let tv = textViewGlobal {
                    tv.window?.makeFirstResponder(nil)
                    tv.setSelectedRange(NSRange(location: 0, length: 0))
                }
#endif
                
                // Carregar conteúdo da nova nota
                loadNoteContent()
                initialized = true
            }
        }
        .onChange(of: isUnlocked) { _, newValue in
            if newValue {
                loadNoteContent()
            }
        }
    }
    
#if os(macOS)
    private func setupFormatObservers() {
        // Remover observadores existentes antes de adicionar novos
        NotificationCenter.default.removeObserver(self)
        
        // Configurar novos observadores
        NotificationCenter.default.addObserver(
            forName: .applyBold,
            object: nil,
            queue: .main
        ) { _ in
            if let textView = textViewGlobal {
                textView.toggleBold()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .applyItalic,
            object: nil,
            queue: .main
        ) { _ in
            if let textView = textViewGlobal {
                textView.toggleItalic()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .applyUnderline,
            object: nil,
            queue: .main
        ) { _ in
            if let textView = textViewGlobal {
                textView.toggleUnderline()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .applyH1,
            object: nil,
            queue: .main
        ) { _ in
            if let textView = textViewGlobal {
                textView.applyHeader(level: 1)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .applyH2,
            object: nil,
            queue: .main
        ) { _ in
            if let textView = textViewGlobal {
                textView.applyHeader(level: 2)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .applyH3,
            object: nil,
            queue: .main
        ) { _ in
            if let textView = textViewGlobal {
                textView.applyHeader(level: 3)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .applyBulletList,
            object: nil,
            queue: .main
        ) { _ in
            if let textView = textViewGlobal {
                textView.applyBullet()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .applyNumberedList,
            object: nil,
            queue: .main
        ) { _ in
            if let textView = textViewGlobal {
                textView.applyNumbered()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .focusEditor,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                if let textView = textViewGlobal {
                    textView.window?.makeFirstResponder(textView)
                }
            }
        }
        
        // Adicionar configuração dos observadores de markdown
    }
#endif
}
