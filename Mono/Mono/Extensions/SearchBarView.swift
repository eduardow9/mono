import SwiftUI
import AppKit

class SearchBarViewController: NSViewController, NSSearchFieldDelegate {
    var searchField: NSSearchField!
    var counterLabel: NSTextField!
    var prevButton: NSButton!
    var nextButton: NSButton!
    var closeButton: NSButton!
    var searchCallback: ((String) -> Void)?
    var nextCallback: (() -> Void)?
    var prevCallback: (() -> Void)?
    var closeCallback: (() -> Void)?
    var currentIndex: Int = 0
    var totalMatches: Int = 0
    
    override func loadView() {
        // Criar diretamente um NSView como container (sem visual effect)
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 45))
        containerView.wantsLayer = true
        
        // Adicionar um background com visual effect mas sem bordas
        let visualEffect = NSVisualEffectView(frame: containerView.bounds)
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 22.5
        visualEffect.layer?.masksToBounds = true
        containerView.addSubview(visualEffect)
        
        // Criar border sutil opcional
        let borderLayer = CALayer()
        borderLayer.frame = visualEffect.bounds
        borderLayer.borderColor = NSColor(white: 1.0, alpha: 0.1).cgColor
        borderLayer.borderWidth = 0.5
        borderLayer.cornerRadius = 22.5
        visualEffect.layer?.addSublayer(borderLayer)
        
        // Campo de busca estilo cápsula
        searchField = NSSearchField(frame: NSRect(x: 45, y: 7, width: 220, height: 31))
        searchField.bezelStyle = .roundedBezel
        searchField.placeholderString = "Buscar no texto"
        searchField.font = NSFont.systemFont(ofSize: 14)
        searchField.focusRingType = .none
        searchField.wantsLayer = true
        searchField.isBordered = false
        searchField.drawsBackground = false
        searchField.backgroundColor = .clear
        searchField.target = self
        searchField.action = #selector(searchTextChanged)
        searchField.delegate = self
        searchField.sendsSearchStringImmediately = true
        
        // Ajustar o ícone de busca para a esquerda
        if let cell = searchField.cell as? NSSearchFieldCell {
            cell.searchButtonCell?.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Buscar")
            cell.searchButtonCell?.imagePosition = .imageLeft
        }
        
        // Contador de resultados
        counterLabel = NSTextField(labelWithString: "0/0")
        counterLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        counterLabel.textColor = NSColor.secondaryLabelColor
        counterLabel.backgroundColor = NSColor.clear
        counterLabel.isEditable = false
        counterLabel.isBordered = false
        counterLabel.alignment = .center
        counterLabel.frame = NSRect(x: 275, y: 12, width: 60, height: 21)
        
        // Botão de navegação anterior
        prevButton = NSButton(frame: NSRect(x: 340, y: 10, width: 25, height: 25))
        prevButton.bezelStyle = .regularSquare
        prevButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Anterior")
        prevButton.imagePosition = .imageOnly
        prevButton.isBordered = false
        prevButton.wantsLayer = true
        prevButton.layer?.backgroundColor = NSColor.clear.cgColor
        prevButton.target = self
        prevButton.action = #selector(previousResult)
        
        // Botão de navegação próximo
        nextButton = NSButton(frame: NSRect(x: 370, y: 10, width: 25, height: 25))
        nextButton.bezelStyle = .regularSquare
        nextButton.image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "Próximo")
        nextButton.imagePosition = .imageOnly
        nextButton.isBordered = false
        nextButton.wantsLayer = true
        nextButton.layer?.backgroundColor = NSColor.clear.cgColor
        nextButton.target = self
        nextButton.action = #selector(nextResult)
        
        // Botão de fechar
        closeButton = NSButton(frame: NSRect(x: 415, y: 10, width: 25, height: 25))
        closeButton.bezelStyle = .regularSquare
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Fechar")
        closeButton.imagePosition = .imageOnly
        closeButton.isBordered = false
        closeButton.wantsLayer = true
        closeButton.layer?.backgroundColor = NSColor.clear.cgColor
        closeButton.target = self
        closeButton.action = #selector(closeSearch)
        
        // Adicionar todos os elementos ao visualEffect (não ao container)
        visualEffect.addSubview(searchField)
        visualEffect.addSubview(counterLabel)
        visualEffect.addSubview(prevButton)
        visualEffect.addSubview(nextButton)
        visualEffect.addSubview(closeButton)
        
        self.view = containerView
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // O NSSearchField aceita primeiro respondedor por padrão
        // Não precisamos definir essas propriedades
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Forçar o foco no campo de busca de várias maneiras
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let window = self.view.window else { return }
            
            // Fazer a janela key
            window.makeKey()
            
            // Fazer o campo primeiro respondedor
            if window.makeFirstResponder(self.searchField) {
                print("Search field became first responder")
            } else {
                print("Failed to make search field first responder")
                // Tentar novamente após um pequeno delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    window.makeFirstResponder(self.searchField)
                    self.searchField.becomeFirstResponder()
                }
            }
            
            // Selecionar todo o texto
            self.searchField.selectText(nil)
        }
        
        // Animar a entrada
        if let layer = self.view.layer {
            layer.opacity = 0
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                self.view.animator().layer?.opacity = 1
            }
        }
    }
    
    @objc func searchTextChanged() {
        searchCallback?(searchField.stringValue)
    }
    
    @objc func previousResult() {
        prevCallback?()
    }
    
    @objc func nextResult() {
        nextCallback?()
    }
    
    @objc func closeSearch() {
        closeCallback?()
    }
    
    func updateCounter(current: Int, total: Int) {
        currentIndex = current
        totalMatches = total
        counterLabel.stringValue = total > 0 ? "\(current + 1)/\(total)" : "0/0"
        
        // Habilitar/desabilitar botões com base no número de resultados
        prevButton.isEnabled = total > 0
        nextButton.isEnabled = total > 0
    }
    
    // MARK: - NSSearchFieldDelegate
    func searchFieldDidStartSearching(_ sender: NSSearchField) {
        searchTextChanged()
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        searchTextChanged()
    }
}
