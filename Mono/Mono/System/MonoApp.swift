import SwiftUI
import AppKit

struct FolderMenuItems: View {
    let folder: FolderEntity
    let level: Int
    @EnvironmentObject var store: NotesStore
    
    var body: some View {
        Button {
            store.moveNotesToFolder(store.selectedNotes, folder: folder)
        } label: {
            HStack {
                Image(systemName: "folder")
                Text(folder.name ?? "Sem nome")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(BorderlessButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 4)
        
        if let subfolders = folder.subfolders?.allObjects as? [FolderEntity], !subfolders.isEmpty {
            Menu {
                ForEach(subfolders.sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.self) { subfolder in
                    FolderMenuItems(folder: subfolder, level: level + 1)
                }
            } label: {
                Text("\(folder.name ?? "Sem nome") >")
                    .padding(.leading, CGFloat(level * 10))
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // O registro do transformador agora é feito no PersistenceController
        
        // Configura a aparência para todas as janelas
        NSWindow.allowsAutomaticWindowTabbing = false
        
        for window in NSApplication.shared.windows {
            configureWindow(window)
        }
    }
    
    func applicationWillUpdate(_ notification: Notification) {
        // Continua configurando novas janelas conforme são criadas
        for window in NSApplication.shared.windows {
            configureWindow(window)
        }
    }
    
    private func configureWindow(_ window: NSWindow) {
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        // window.backgroundColor = NSColor(named: "FrameColor") // removido para permitir translucidez
        
        // Remove o título da janela
        window.title = ""
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        
        // Configuração da toolbar nativa sem usar showsBaselineSeparator
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.displayMode = .iconOnly
        // Removida a linha showsBaselineSeparator que foi depreciada
        window.toolbar = toolbar
    }
}

@main
struct MonoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    
    @StateObject private var store = NotesStore(context: PersistenceController.shared.container.viewContext)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .background(Color("FrameColor"))
                
                // Removida a configuração toolbar que causava ambiguidades
        }
        
        WindowGroup("noteWindow", id: "noteWindow", for: UUID.self) { $noteID in
            if let id = noteID, let index = store.notes.firstIndex(where: { $0.id == id }) {
                EditorView(note: $store.notes[index])
                    .background(Color("FrameColor"))
                    
            }
        }
        .environmentObject(store)
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        
        .commands {
            CommandGroup(replacing: .textEditing) {
                Button("Apagar Nota") {
                    if !store.selectedNotes.isEmpty {
                        store.deleteMultipleNotes(store.selectedNotes)
                    } else if let selected = store.selectedNote {
                        store.deleteNote(selected)
                    }
                }
                .keyboardShortcut(.delete, modifiers: [])
                
                Divider()
                
                Button("Apagar Pasta") {
                    if let folder = store.selectedFolder, !folder.isSystemFolder {
                        let alert = NSAlert()
                        alert.messageText = "Tem certeza que deseja apagar esta pasta?"
                        alert.informativeText = "Esta ação não pode ser desfeita."
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "Apagar")
                        alert.addButton(withTitle: "Cancelar")
                        
                        if alert.runModal() == .alertFirstButtonReturn {
                            store.deleteFolder(folder)
                        }
                    }
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                
                Divider()
                
                Button("Selecionar Todas as Notas") {
                    store.selectedNotes = Set(store.notes)
                }
                .keyboardShortcut("a", modifiers: [.command])
            }
            
            CommandMenu("Notas") {
                Button("Nova Nota") {
                    store.createNewNote()
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                if !store.selectedNotes.isEmpty && store.selectedNotes.count >= 1 {
                    Divider()
                    
                    Button(store.selectedNotes.allSatisfy({ $0.isPinned }) ? "Desafixar Notas" : "Fixar Notas") {
                        store.togglePinForNotes(store.selectedNotes)
                    }
                    .keyboardShortcut("p", modifiers: [.command])
                    
                    Menu {
                        Button("Sem Pasta") {
                            store.moveNotesToFolder(store.selectedNotes, folder: nil)
                        }
                        
                        if !store.folders.isEmpty {
                            Divider()
                            
                            ForEach(store.folders.filter { $0.parentFolder == nil }) { folder in
                                FolderMenuItems(folder: folder, level: 0)
                            }
                        }
                    } label: {
                        Text("Mover Para Pasta")
                    }
                }
            }
            
            CommandMenu("Formatação") {
                Button("Negrito") {
                    NotificationCenter.default.post(name: .applyBold, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command])
                
                Button("Itálico") {
                    NotificationCenter.default.post(name: .applyItalic, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command])
                
                Button("Sublinhado") {
                    NotificationCenter.default.post(name: .applyUnderline, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command])
                
                Divider()
                
                Button("Título 1") {
                    NotificationCenter.default.post(name: .applyH1, object: nil)
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])
                
                Button("Título 2") {
                    NotificationCenter.default.post(name: .applyH2, object: nil)
                }
                .keyboardShortcut("2", modifiers: [.command, .shift])
                
                Button("Título 3") {
                    NotificationCenter.default.post(name: .applyH3, object: nil)
                }
                .keyboardShortcut("3", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Lista com Marcadores") {
                    NotificationCenter.default.post(name: .applyBulletList, object: nil)
                }
                .keyboardShortcut("8", modifiers: [.command, .shift])
                
                Button("Lista Numerada") {
                    NotificationCenter.default.post(name: .applyNumberedList, object: nil)
                }
                .keyboardShortcut("9", modifiers: [.command, .shift])
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotesStore(context: PersistenceController.shared.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .frame(width: 1200, height: 700)
}
