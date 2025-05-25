import SwiftUI
#if os(macOS)
import AppKit
#endif
import Combine

struct ContentView: View {  
    @EnvironmentObject var store: NotesStore

    var body: some View {
#if os(macOS)
        MainLayoutView()
            .environmentObject(store)
#else
        MainView_iOS()
            .environmentObject(store)
#endif
    }
    
#if os(macOS)
    // Função para configurar a aparência da janela
    private func configureWindowAppearance() {
        let window = NSApplication.shared.windows.first { $0.isKeyWindow }
        window?.titlebarAppearsTransparent = true
        window?.backgroundColor = NSColor(named: "FrameColor")
        
        // Adicionar botão de toggle da barra lateral
        addSidebarToggleButton(to: window)
        
        // Configura a aparência para cada parte do aplicativo
        for subview in window?.contentView?.subviews ?? [] {
            if let identifier = subview.identifier?.rawValue {
                if identifier.contains("sidebar") {
                    subview.layer?.backgroundColor = NSColor(named: "SidebarColor")?.cgColor
                } else {
                    subview.layer?.backgroundColor = NSColor(named: "FrameColor")?.cgColor
                }
            }
        }
    }
#endif
    
#if os(macOS)
    // 7. Corrigir posicionamento do botão de toggle sidebar

    private func addSidebarToggleButton(to window: NSWindow?) {
        guard let window = window else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Usar um botão padrão do NSWindow
            let button = NSButton()
            button.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Toggle Sidebar")
            button.imagePosition = .imageOnly
            button.bezelStyle = .texturedRounded
            button.isBordered = true
            button.translatesAutoresizingMaskIntoConstraints = false
            button.toolTip = "Mostrar/Ocultar barra lateral"
            
            // Configurar o botão para chamar a ação
            button.target = ToggleSidebarActionHandler.shared
            button.action = #selector(ToggleSidebarActionHandler.toggleSidebar(_:))
            
            // Adicionar à barra de título
            if let titleBarView = window.standardWindowButton(.closeButton)?.superview {
                titleBarView.addSubview(button)
                
                // Posicionar à direita do botão de zoom (o terceiro botão de controle da janela)
                if let zoomButton = window.standardWindowButton(.zoomButton) {
                    NSLayoutConstraint.activate([
                        button.centerYAnchor.constraint(equalTo: zoomButton.centerYAnchor),
                        button.leadingAnchor.constraint(equalTo: zoomButton.trailingAnchor, constant: 12),
                        button.widthAnchor.constraint(equalToConstant: 28),
                        button.heightAnchor.constraint(equalToConstant: 24)
                    ])
                }
            }
        }
    }
#endif
}

#if os(macOS)
// Singleton para gerenciar a ação de toggle da barra lateral
class ToggleSidebarActionHandler: NSObject {
    static let shared = ToggleSidebarActionHandler()
    
    @objc func toggleSidebar(_ sender: NSButton) {
        // Postar uma notificação que será capturada pelo MainLayoutView
        NotificationCenter.default.post(name: .toggleSidebar, object: nil)
    }
}
#endif
