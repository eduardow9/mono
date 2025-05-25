import SwiftUI

struct SidebarView_iOS: View {
    @EnvironmentObject private var store: NotesStore
    @Binding var selection: FolderEntity?

    /// Pastas ordenadas: Todas as notas → pastas do usuário (A‑Z) → Arquivadas → Apagadas
    private var orderedFolders: [FolderEntity] {
        let all = store.folders
        let allNotes = all.first { $0.systemKind == .allNotes }
        let archived = all.first { $0.systemKind == .archived }
        let trash = all.first { $0.systemKind == .trash }
        let userFolders = all.filter { $0.systemKind == nil }
                             .sorted { ($0.name ?? "") < ($1.name ?? "") }

        return [allNotes].compactMap { $0 } +
               userFolders +
               [archived, trash].compactMap { $0 }
    }

    // MARK: - View body
    var body: some View {
        List {
            foldersSection
            tagsSection
        }
        .navigationTitle("Pastas")
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.addFolder(name: "Nova pasta")
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        // Propaga a pasta selecionada para o NotesStore
        .onChange(of: selection) { _, newValue in
            store.selectedFolder = newValue
        }
    }

    // MARK: - Private helpers
    /// Seção que lista todas as pastas
    private var foldersSection: some View {
        Section("Pastas") {
            ForEach(orderedFolders) { folder in
                NavigationLink(value: folder) {
                    Text(folder.name ?? "Sem nome")
                }
            }
            .onDelete { indexSet in
                for idx in indexSet {
                    let folder = orderedFolders[idx]
                    if folder.systemKind == nil {        // só pastas do usuário
                        store.deleteFolder(folder)
                    }
                }
            }
        }
    }

    /// Seção que lista todas as etiquetas (tags)
    private var tagsSection: some View {
        Group {
            if !store.tags.isEmpty {
                Section("Etiquetas") {
                    ForEach(store.tags, id: \.id) { tag in
                        Text(tag.name)
                    }
                }
            }
        }
    }
}
