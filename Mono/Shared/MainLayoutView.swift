import SwiftUI
import CoreData

#if os(macOS)
import AppKit
#endif

struct MainLayoutView: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.horizontalSizeClass) private var sizeClass   // iPhone vs iPad/mac

    @State private var sidebarWidth: CGFloat        = 250
    @State private var notesListWidth: CGFloat      = 300
    @State private var previousSidebarWidth: CGFloat = 250
    @State private var isSidebarVisible: Bool       = true
    @State private var showDeleteConfirmation       = false
    @State private var searchText: String           = ""
    /// Pasta selecionada (iOS / iPadOS NavigationStack & SplitView)
    @State private var folderSelection: FolderEntity?

    // Controlador de busca é usado só no macOS
    #if os(macOS)
    @StateObject private var searchController =
        SearchController(store: NotesStore(context: PersistenceController.shared.container.viewContext))
    #endif

    var body: some View {
        #if os(iOS)
        if sizeClass == .compact {
            NavigationStack {
                SideBarView_iOS(selection: $folderSelection)
                    .navigationDestination(for: FolderEntity.self) { _ in
                        NotesListView(searchText: searchText)
                            .environmentObject(store)
                    }
            }
        } else {
            desktopBody
        }
        #else
        desktopBody
        #endif
    }

    // MARK: – Layout desktop / iPad
    private var desktopBody: some View {
        HStack(spacing: 0) {

            if isSidebarVisible {
                // ---------- Sidebar ----------
                ZStack {
                    #if os(macOS)
                    SidebarView()
                    #else
                    SideBarView_iOS(selection: $folderSelection)
                    #endif
                }
                .padding(.top, 28)
                .background(Color("SidebarColor"))
                .frame(width: sidebarWidth)          // ← separa
                .frame(maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.move(edge: .leading))

#if os(macOS)
ResizableDivider(width: $sidebarWidth)
#endif
            }

            // ─────────── Painel central (lista de notas) ───────────
            ZStack {
                Color("FrameColor").ignoresSafeArea()

                VStack(spacing: 5) {

                    // Cabeçalho
                    headerBar

                    // Barra de busca
                    searchBar

                    // Barra de ferramentas para seleção múltipla
                    if store.selectedNotes.count > 1 {
                        MultiSelectionToolbar()
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            #if os(macOS)
                            .background(Color(NSColor.controlBackgroundColor))
                            #else
                            .background(Color("FrameColor"))
                            #endif
                            .overlay(
                                Divider(),
                                alignment: .bottom
                            )
                    }

                    // Lista de notas
                    notesList
                }
            }
            .frame(width: notesListWidth, alignment: .leading)

            // Divider entre lista e editor
            ResizableDivider(width: $notesListWidth)

            // ─────────── Editor ───────────
            editorPane
        }
        .alert("Excluir notas?", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Excluir", role: .destructive) {
                store.deleteMultipleNotes(store.selectedNotes)
            }
        } message: {
            Text("Você está prestes a excluir \(store.selectedNotes.count) notas. Esta ação não pode ser desfeita.")
        }
        .onAppear {
            #if os(macOS)
            searchController.store = store
            #endif
            addSidebarToggleObserver()
        }
        .onDisappear { NotificationCenter.default.removeObserver(self) }
        .animation(.easeInOut(duration: 0.2), value: isSidebarVisible)
    }

    // MARK: – Componentes

    // Cabeçalho com título da pasta e botão nova nota
    private var headerBar: some View {
        HStack {
            Text(folderTitle)
                .font(.headline)
                .foregroundColor(Color.monoTextSecondary)
                .padding(.leading, 20)

            Spacer()

            Button { store.createNewNote() } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(Color.monoTextPrimary)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 15)
        }
        .frame(height: 30)
        .background(Color("FrameColor"))
    }

    // Barra de busca (CustomSearchField no macOS, TextField no iOS)
    private var searchBar: some View {
        ZStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.monoTextSecondary.opacity(0.6))
                    .padding(.leading, 10)

                #if os(macOS)
                CustomSearchField(
                    text: $searchController.searchText,
                    onCommit: { searchController.search() },
                    onEscapePressed: { searchController.clearSearch() }
                )
                .font(.system(size: 14))
                .padding(.vertical, 6)
                #else
                TextField("Buscar", text: $searchText)
                #endif

                #if os(macOS)
                if searchController.isSearchActive && !searchController.searchResults.isEmpty {
                    Divider().frame(height: 16)
                    Text("\(searchController.selectedResultIndex + 1)/\(searchController.searchResults.count)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.monoTextSecondary)
                    Button { searchController.previousResult() } label: {
                        Image(systemName: "chevron.up")
                    }.buttonStyle(.plain)
                    Button { searchController.nextResult() } label: {
                        Image(systemName: "chevron.down")
                    }.buttonStyle(.plain)
                }

                if !searchController.searchText.isEmpty {
                    Button { searchController.clearSearch() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.monoTextSecondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 10)
                }
                #else
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.monoTextSecondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 10)
                }
                #endif
            }
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.monoTextSecondary.opacity(0.2), lineWidth: 0.5))
        }
        .padding(.horizontal, 15)
        #if os(macOS)
        .onAppear { addSearchShortcut() }
        #endif
    }

    // Lista de notas
    private var notesList: some View {
        Group {
        #if os(macOS)
            NotesListView(searchText: searchController.searchText)
        #else
            NotesListView(searchText: searchText)
        #endif
        }
        .environmentObject(store)
        .background(Color("FrameColor"))
        #if os(macOS)
        .onDeleteCommand { store.deleteMultipleNotes(store.selectedNotes) }
        #endif
#if os(macOS)
        .onKeyDown { event in
            guard event.keyCode == 51 else { return false }
            return handleDeleteShortcut()
        }
#endif
    }

    // Editor
    private var editorPane: some View {
        ZStack {
            Color("FrameColor").ignoresSafeArea()

            if let selectedNote = store.selectedNote,
               let idx = store.notes.firstIndex(where: { $0.id == selectedNote.id }) {

                VStack(spacing: 0) {
                    editorToolbar(for: selectedNote)

                    EditorView(note: $store.notes[idx])
                        .padding(30)  // Padding do Editor para as bordas
                        #if os(macOS)
                        .onChange(of: selectedNote.id) { _, _ in
                            if searchController.isSearchActive && !searchController.searchText.isEmpty {
                                searchController.search()
                            }
                        }
                        #endif
                }
            } else {
                Text("Nenhuma nota selecionada")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 400)
    }

    // Toolbar do editor
    private func editorToolbar(for note: NoteEntity) -> some View {
        HStack(spacing: 0) {
            formatButtons
            Spacer()
            if store.selectedNote != nil {
                lockButton(for: note)
                Divider().frame(width: 30, height: 30)
                exportMenu
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(Color("FrameColor"))
    }

    private var formatButtons: some View {
        Group {
            Button { sendFormatNotification(.applyBold) }       label: { Image(systemName: "bold") }
            Button { sendFormatNotification(.applyItalic) }     label: { Image(systemName: "italic") }
            Button { sendFormatNotification(.applyUnderline) }  label: { Image(systemName: "underline") }
            Divider().frame(height: 20)
            Button { sendFormatNotification(.applyH1) } label: { Text("H1").font(.subheadline).fontWeight(.semibold) }
            Button { sendFormatNotification(.applyH2) } label: { Text("H2").font(.subheadline).fontWeight(.semibold) }
            Button { sendFormatNotification(.applyH3) } label: { Text("H3").font(.subheadline).fontWeight(.semibold) }
            Divider().frame(height: 20)
            Button { sendFormatNotification(.applyBulletList) }   label: { Image(systemName: "list.bullet") }
            Button { sendFormatNotification(.applyNumberedList) } label: { Image(systemName: "list.number") }
        }
        .buttonStyle(.plain)
        .frame(width: 30, height: 30)
        .foregroundColor(Color.monoTextPrimary)
    }

    // Botão de bloqueio/desbloqueio (somente macOS)
    private func lockButton(for note: NoteEntity) -> some View {
        #if os(macOS)
        Button {
            if note.isLocked {
                BiometricAuth.authenticate(reason: "Desbloquear nota: \(formatTitle(note.title ?? ""))") { success in
                    if success { toggleLock(for: note) }
                }
            } else {
                toggleLock(for: note)
            }
        } label: {
            Image(systemName: note.isLocked ? "lock.open" : "lock")
        }
        .buttonStyle(.plain)
        .frame(width: 10, height: 30)
        #else
        EmptyView()
        #endif
    }

    private var exportMenu: some View {
        Menu {
            Button("Exportar como PDF") { /* implementar */ }
            Button("Exportar como TXT") { /* implementar */ }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(Color.monoTextPrimary)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 30, height: 30)
        .buttonStyle(.plain)
    }

    // MARK: – Helpers

    private func toggleLock(for note: NoteEntity) {
        note.isLocked.toggle()
        try? store.context.save()
    }

    private func handleDeleteShortcut() -> Bool {
        if let note = store.selectedNote {
            store.selectedFolder == store.trashFolder ?
                store.permanentlyDeleteNote(note) :
                store.deleteNote(note)
            return true
        } else if !store.selectedNotes.isEmpty {
            store.selectedFolder == store.trashFolder ?
                store.selectedNotes.forEach { store.permanentlyDeleteNote($0) } :
                store.deleteMultipleNotes(store.selectedNotes)
            return true
        } else if let folder = store.selectedFolder,
                  !folder.isSystem,
                  store.selectedNote == nil,
                  store.selectedNotes.isEmpty {
            #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Tem certeza que deseja apagar esta pasta?"
            alert.informativeText = "Esta ação não pode ser desfeita."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Apagar")
            alert.addButton(withTitle: "Cancelar")
            if alert.runModal() == .alertFirstButtonReturn {
                store.deleteFolder(folder)
            }
            #endif
            return true
        }
        return false
    }

    #if os(macOS)
    private func addSearchShortcut() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.contains(.command),
                  event.charactersIgnoringModifiers == "f",
                  let window = NSApp.keyWindow,
                  !(window.firstResponder is NSTextView) else { return event }
            NotificationCenter.default.post(name: .activateListSearch, object: nil)
            return nil
        }
    }
    #endif

    private func addSidebarToggleObserver() {
        NotificationCenter.default.addObserver(
            forName: .toggleSidebar, object: nil, queue: .main
        ) { _ in
            withAnimation {
                isSidebarVisible.toggle()
            if isSidebarVisible {
                    sidebarWidth = previousSidebarWidth
                } else {
                    previousSidebarWidth = sidebarWidth
                    sidebarWidth = 0
                }
            }
        }
    }

    private var folderTitle: String {
        guard let folder = store.selectedFolder else { return "Todas as Notas" }
        if folder == store.allNotesFolder   { return "Todas as Notas" }
        if folder == store.trashFolder      { return "Lixeira" }
        if folder == store.archivedFolder   { return "Arquivadas" }
        return folder.name ?? "Sem nome"
    }

    private func sendFormatNotification(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
    
    private func formatTitle(_ title: String) -> String {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty {
            return "Sem título"
        }
        if cleanTitle.count > 30 {
            return String(cleanTitle.prefix(30)) + "..."
        }
        return cleanTitle
    }
}
