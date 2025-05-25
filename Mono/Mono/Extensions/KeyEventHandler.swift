import SwiftUI
import AppKit

// Extensão para manipulação de teclas
extension View {
    func onKeyDown(handler: @escaping (NSEvent) -> Bool) -> some View {
        self.background(
            KeyEventHandlerView(handler: handler)
                .frame(width: 0, height: 0)
        )
    }
}

// Implementação do manipulador de eventos de teclado
struct KeyEventHandlerView: NSViewRepresentable {
    let handler: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> KeyHandlerNSView {
        let view = KeyHandlerNSView()
        view.handler = handler
        return view
    }
    
    func updateNSView(_ nsView: KeyHandlerNSView, context: Context) {
        nsView.handler = handler
    }
    
    class KeyHandlerNSView: NSView {
        var handler: ((NSEvent) -> Bool)?
        
        override var acceptsFirstResponder: Bool {
            return true
        }
        
        // Em NSView, keyDown retorna void, não Bool
        override func keyDown(with event: NSEvent) {
            if let handler = handler, handler(event) {
                // Se o handler retornar true, consideramos o evento tratado
                return
            }
            // Se o handler retornar false ou não existir, passamos para a implementação padrão
            super.keyDown(with: event)
        }
    }
}
