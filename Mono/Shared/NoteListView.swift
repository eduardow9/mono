import SwiftUI

struct NotesListView: View {
    @EnvironmentObject var store: NotesStore
    var searchText: String = ""
    @Environment(\.colorScheme) private var colorScheme

    private var pinned: [NoteEntity] {
        let filteredNotes = store.filteredNotes
            .filter { $0.isPinned && $0.id != nil }
            .sorted { ($0.dateModified ?? .distantPast) > ($1.dateModified ?? .distantPast) }
        
        if searchText.isEmpty {
            return filteredNotes
        } else {
            return filteredNotes.filter {
                $0.title?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.content?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    private var filteredUnpinnedNotes: [NoteEntity] {
        let filteredNotes = store.filteredNotes
            .filter { !$0.isPinned }
            .sorted { ($0.dateModified ?? .distantPast) > ($1.dateModified ?? .distantPast) }
        
        if searchText.isEmpty {
            return filteredNotes
        } else {
            return filteredNotes.filter {
                $0.title?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.content?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    private var groupedNotes: [DateGroup: [NoteEntity]] {
        // Se estamos na lixeira, mostramos todas as notas em uma lista simples
        if store.selectedFolder == store.trashFolder {
            return [.older: filteredUnpinnedNotes]
        }
        
        // Caso contrário, agrupamos por data
        return Dictionary(grouping: filteredUnpinnedNotes) { note -> DateGroup in
            guard let createdAt = note.dateModified else { return .older }
            let days = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0

            switch days {
            case 0: return .today
            case 1...7: return .last7
            case 8...15: return .last15
            case 16...30: return .last30
            default: return .older
            }
        }
    }

    var body: some View {
#if os(macOS)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Mostra notas fixadas apenas se não estiver na lixeira
                if store.selectedFolder != store.trashFolder {
                    PinnedNotesSection(pinned: pinned)
                        .environmentObject(store)
                }

                ForEach(DateGroup.allCases, id: \.rawValue) { group in
                    if let notes = groupedNotes[group], !notes.isEmpty {
                        GroupedNotesSection(group: group, notes: notes)
                            .environmentObject(store)
                    }
                }
                
                // Mensagem quando não há notas
                if store.filteredNotes.isEmpty {
                    VStack {
                        Spacer()
                        if store.selectedFolder == store.trashFolder {
                            Text("A Lixeira está vazia")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Nenhuma nota nesta pasta")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Button("Nova Nota") {
                                store.createNewNote()
                            }
                            .padding(.top)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .background(Color("FrameColor"))
        #if os(macOS)
        .onDeleteCommand {
            if !store.selectedNotes.isEmpty {
                deleteSelectedNotes()
            } else if let selected = store.selectedNote {
                store.deleteNote(selected)
            }
        }
        #endif
#else
        // ───────── iOS / iPadOS ─────────
        List {
            ForEach(store.filteredNotes) { note in
                NavigationLink {
                    EditorView(note: .constant(note))
                        .environmentObject(store)
                } label: {
                    NoteRow(note: note, isSelected: store.selectedNote == note)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())   // remove default padding
                .listRowBackground(Color.clear)
                .padding(.vertical, 16)   // Altura do cartão
                .padding(.horizontal, 20)   // Padding do texto do cartão
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        store.deleteNote(note)
                    } label: {
                        Label("Apagar", systemImage: "trash")
                    }
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 15)
        }
        .listStyle(.plain)
        .listRowSpacing(8)        // Espaço vertical entre cartões
        .scrollContentBackground(.hidden)
        .background(Color("FrameColor"))
        .listSectionSeparator(.hidden)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.createNewNote()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
#endif
        // Botões invisíveis para atalhos de teclado (somente quando o editor NÃO é primeiro‑respondente)
        #if os(macOS)
        Color.clear
            .frame(width: 0, height: 0)
            .background(
                Group {
                    if let window = NSApp.keyWindow,
                       !(window.firstResponder is NSTextView) {
                        HStack {
                            // Selecionar todas as notas
                            Button("Selecionar Todas") {
                                store.selectedNotes = Set(store.filteredNotes)
                                // Remove foco do editor, garantindo que ⌘A permaneça na lista
                                if let tv = textViewGlobal,
                                   tv.window?.firstResponder === tv {
                                    tv.window?.makeFirstResponder(nil)
                                }
                            }
                            .keyboardShortcut("a", modifiers: [.command])
                            
                            // Cancelar Seleção
                            Button("Cancelar Seleção") {
                                store.selectedNotes.removeAll()
                                if let note = store.selectedNote {
                                    store.selectedNotes.insert(note)
                                }
                                // Também remove foco do editor
                                if let tv = textViewGlobal,
                                   tv.window?.firstResponder === tv {
                                    tv.window?.makeFirstResponder(nil)
                                }
                            }
                            .keyboardShortcut(.escape)
                            
                            // Fixar / Desafixar
                            Button("Fixar/Desafixar") {
                                if !store.selectedNotes.isEmpty {
                                    store.togglePinForNotes(store.selectedNotes)
                                } else if let note = store.selectedNote {
                                    store.togglePinForNotes([note])
                                }
                            }
                            .keyboardShortcut("p", modifiers: [.command])
                        }
                        .opacity(0) // Invisível, só para capturar atalhos
                    }
                }
            )
        #endif
    }
    
    private func deleteSelectedNotes() {
        if store.selectedFolder == store.trashFolder {
            // Se estiver na lixeira, exclui permanentemente
            for note in store.selectedNotes {
                store.permanentlyDeleteNote(note)
            }
        } else {
            // Caso contrário, move para a lixeira
            store.deleteMultipleNotes(store.selectedNotes)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotesStore(context: PersistenceController.shared.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .frame(width: 1200, height: 700)
}
