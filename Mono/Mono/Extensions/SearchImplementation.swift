import SwiftUI
import AppKit

// Extensões para Notification.Name
extension Notification.Name {
    static let clearSearch = Notification.Name("clearSearch")
    static let activateListSearch = Notification.Name("activateListSearch")
}

// Modelo para resultados de busca
struct SearchResult {
    let note: NoteEntity
    let ranges: [NSRange]  // Posições da palavra de busca no texto
    var currentMatch: Int = 0  // Índice do resultado atual
    
    var totalMatches: Int {
        return ranges.count
    }
    
    var currentRange: NSRange? {
        guard !ranges.isEmpty, currentMatch < ranges.count else { return nil }
        return ranges[currentMatch]
    }
    
    mutating func nextMatch() {
        if !ranges.isEmpty {
            currentMatch = (currentMatch + 1) % ranges.count
        }
    }
    
    mutating func previousMatch() {
        if !ranges.isEmpty {
            currentMatch = (currentMatch - 1 + ranges.count) % ranges.count
        }
    }
}

// Controlador da interface de busca
class SearchController: ObservableObject {
    @Published var searchText: String = ""
    @Published var isSearchActive: Bool = false
    @Published var searchResults: [NoteEntity] = []
    @Published var selectedResultIndex: Int = 0
    
    var store: NotesStore
    
    init(store: NotesStore) {
        self.store = store
        
        // Observadores para eventos de busca
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClearSearch),
            name: .clearSearch,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivateSearch),
            name: .activateListSearch,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleActivateSearch() {
        DispatchQueue.main.async { [weak self] in
            // Ativar o campo de busca
            self?.isSearchActive = true
            
            // Dar foco ao campo de busca
            if let window = NSApplication.shared.keyWindow {
                // Procurar pelo campo de busca na hierarquia de views
                if let searchField = self?.findSearchField(in: window.contentView) {
                    window.makeFirstResponder(searchField)
                }
            }
        }
    }
    
    private func findSearchField(in view: NSView?) -> NSView? {
        // Procura recursivamente por um NSSearchField ou NSTextField
        if let view = view {
            if view is NSSearchField || (view is NSTextField && view.identifier?.rawValue == "searchField") {
                return view
            }
            
            for subview in view.subviews {
                if let found = findSearchField(in: subview) {
                    return found
                }
            }
        }
        return nil
    }
    
    @objc func handleClearSearch() {
        DispatchQueue.main.async { [weak self] in
            self?.clearSearch()
        }
    }
    
    func search() {
        guard !searchText.isEmpty else {
            isSearchActive = false
            searchResults = []
            return
        }
        
        isSearchActive = true
        
        // Filtrar notas que contêm o termo de busca
        searchResults = store.filteredNotes.filter { note in
            guard let content = note.content else { return false }
            return content.localizedCaseInsensitiveContains(searchText) ||
                   (note.title?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        // Se há resultados, seleciona o primeiro
        if !searchResults.isEmpty {
            selectedResultIndex = 0
            store.selectedNote = searchResults[selectedResultIndex]
            store.selectedNotes = [searchResults[selectedResultIndex]]
        }
    }
    
    func nextResult() {
        guard !searchResults.isEmpty else { return }
        
        selectedResultIndex = (selectedResultIndex + 1) % searchResults.count
        store.selectedNote = searchResults[selectedResultIndex]
        store.selectedNotes = [searchResults[selectedResultIndex]]
    }
    
    func previousResult() {
        guard !searchResults.isEmpty else { return }
        
        selectedResultIndex = (selectedResultIndex - 1 + searchResults.count) % searchResults.count
        store.selectedNote = searchResults[selectedResultIndex]
        store.selectedNotes = [searchResults[selectedResultIndex]]
    }
    
    func clearSearch() {
        searchText = ""
        isSearchActive = false
        searchResults = []
    }
}

// Extensão para buscar nas notas
extension NotesStore {
    // Busca nas notas e armazena os resultados
    func searchInNotes(_ searchText: String) -> SearchResult? {
        guard !searchText.isEmpty,
              let selectedNote = selectedNote,
              let content = selectedNote.content else {
            return nil
        }
        
        // Criar uma expressão regular que encontre o termo de busca ignorando maiúsculas/minúsculas
        do {
            let regex = try NSRegularExpression(
                pattern: NSRegularExpression.escapedPattern(for: searchText),
                options: [.caseInsensitive]
            )
            
            // Buscar todas as ocorrências
            let nsContent = content as NSString
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length))
            
            // Extrair os ranges de cada match
            let ranges = matches.map { $0.range }
            
            if !ranges.isEmpty {
                return SearchResult(note: selectedNote, ranges: ranges)
            }
        } catch {
            print("Erro ao criar regex para busca: \(error)")
        }
        
        return nil
    }
}

// CustomSearchField para usar nas views
struct CustomSearchField: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
    var onEscapePressed: () -> Void
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = "Buscar notas"
        textField.delegate = context.coordinator
        textField.focusRingType = .none
        textField.bezelStyle = .roundedBezel
        textField.isBordered = false
        textField.backgroundColor = NSColor.clear
        textField.identifier = NSUserInterfaceItemIdentifier("searchField")
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomSearchField
        
        init(_ parent: CustomSearchField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                // ESC pressionado
                parent.onEscapePressed()
                return true
            }
            
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Enter pressionado
                parent.onCommit()
                return true
            }
            
            return false
        }
    }
}

class EditorSearchController: NSObject {
    var textView: NSTextView
    var searchResults: [NSRange] = []
    var currentResultIndex: Int = 0
    var isActive: Bool = false
    var searchTerm: String = ""
    var searchBarViewController: SearchBarViewController?
    var searchBarWindow: NSWindow?
    
    init(textView: NSTextView) {
        self.textView = textView
        super.init()
        
        // Registrar para notificação de mudança de nota
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(noteSelectionChanged),
            name: NSWindow.didResignKeyNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func noteSelectionChanged() {
        // Quando a seleção de nota mudar, esconder a barra de busca
        hideSearchBar()
    }
    
    func showSearchBar() {
        // Se já existe, apenas dá foco
        if let existingWindow = searchBarWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            existingWindow.makeFirstResponder(searchBarViewController?.searchField)
            searchBarViewController?.searchField.selectText(nil)
            return
        }
        
        // Criar a janela de busca
        let searchBarVC = SearchBarViewController()
        searchBarViewController = searchBarVC
        
        // Criar janela sem bordas, sem título
        let searchWindow = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 45),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        searchWindow.contentViewController = searchBarVC
        searchWindow.backgroundColor = .clear
        searchWindow.isOpaque = false
        searchWindow.hasShadow = false
        searchWindow.level = .modalPanel
        searchWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        searchWindow.hidesOnDeactivate = false
        searchWindow.isReleasedWhenClosed = false
        
        // Configurar callbacks
        searchBarVC.searchCallback = { [weak self] text in
            self?.search(for: text)
        }
        
        searchBarVC.prevCallback = { [weak self] in
            self?.previousMatch()
        }
        
        searchBarVC.nextCallback = { [weak self] in
            self?.nextMatch()
        }
        
        searchBarVC.closeCallback = { [weak self] in
            self?.hideSearchBar()
        }
        
        // Posicionar a janela de busca acima do editor
        if let editorWindow = textView.window {
            let editorFrame = textView.convert(textView.bounds, to: nil)
            let windowFrame = editorWindow.convertToScreen(editorFrame)
            
            let searchBarX = windowFrame.origin.x + (windowFrame.width - 480) / 2
            let searchBarY = windowFrame.origin.y + windowFrame.height - 80
            
            searchWindow.setFrameOrigin(NSPoint(x: searchBarX, y: searchBarY))
            editorWindow.addChildWindow(searchWindow, ordered: .above)
        }
        
        // Mostrar a janela primeiro
        searchWindow.orderFront(nil)
        searchWindow.makeKeyAndOrderFront(nil)
        
        // Esperar um pouco antes de definir o foco
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Forçar o foco no campo de busca
            searchWindow.makeKey()
            searchWindow.makeFirstResponder(searchBarVC.searchField)
            searchBarVC.searchField.becomeFirstResponder()
            searchBarVC.searchField.selectText(nil)
        }
        
        searchBarWindow = searchWindow
        isActive = true
    }
    
    func hideSearchBar() {
        guard let window = searchBarWindow else { return }
        
        // Animação de saída
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            window.orderOut(nil)
            if let parentWindow = window.parent {
                parentWindow.removeChildWindow(window)
            }
        })
        
        clearSearch()
        isActive = false
    }
    
    func search(for text: String) {
        guard !text.isEmpty else {
            clearHighlights()
            searchBarViewController?.updateCounter(current: 0, total: 0)
            searchResults = []
            return
        }
        
        searchTerm = text
        searchResults = []
        
        let content = textView.string
        let nsContent = content as NSString
        
        // Buscar todas as ocorrências
        do {
            let regex = try NSRegularExpression(
                pattern: NSRegularExpression.escapedPattern(for: text),
                options: [.caseInsensitive]
            )
            
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length))
            searchResults = matches.map { $0.range }
            
            if !searchResults.isEmpty {
                currentResultIndex = 0
                highlightCurrentMatch()
                searchBarViewController?.updateCounter(current: currentResultIndex, total: searchResults.count)
            } else {
                searchBarViewController?.updateCounter(current: 0, total: 0)
            }
        } catch {
            print("Erro ao criar regex para busca no editor: \(error)")
        }
    }
    
    func nextMatch() {
        guard !searchResults.isEmpty else { return }
        
        currentResultIndex = (currentResultIndex + 1) % searchResults.count
        highlightCurrentMatch()
        searchBarViewController?.updateCounter(current: currentResultIndex, total: searchResults.count)
    }
    
    func previousMatch() {
        guard !searchResults.isEmpty else { return }
        
        currentResultIndex = (currentResultIndex - 1 + searchResults.count) % searchResults.count
        highlightCurrentMatch()
        searchBarViewController?.updateCounter(current: currentResultIndex, total: searchResults.count)
    }
    
    func highlightCurrentMatch() {
        guard currentResultIndex < searchResults.count else { return }
        
        // Remover destaques anteriores
        clearHighlights()
        
        // Destacar todos os resultados
        let storage = textView.textStorage!
        
        // Destacar todos os resultados com cinza claro
        for (index, range) in searchResults.enumerated() {
            let color = (index == currentResultIndex) ? NSColor.yellow : NSColor(white: 0.95, alpha: 1.0)
            storage.addAttribute(.backgroundColor, value: color, range: range)
        }
        
        // Rolar para mostrar o resultado atual
        let currentRange = searchResults[currentResultIndex]
        textView.scrollRangeToVisible(currentRange)
        
        // Selecionar o texto
        textView.setSelectedRange(currentRange)
    }
    
    private func clearHighlights() {
        let storage = textView.textStorage!
        let fullRange = NSRange(location: 0, length: storage.length)
        storage.removeAttribute(.backgroundColor, range: fullRange)
    }
    
    func clearSearch() {
        searchResults = []
        searchTerm = ""
        clearHighlights()
    }
}
