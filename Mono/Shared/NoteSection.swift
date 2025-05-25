import SwiftUI
import CoreData

enum DateGroup: String, CaseIterable, Hashable {
    case today = "Hoje"
    case last7 = "Últimos 7 dias"
    case last15 = "Últimos 15 dias"
    case last30 = "Últimos 30 dias"
    case older = "Antigas"
}

struct NoteSection: View {
    @ObservedObject var store: NotesStore
    
    var body: some View {
        // Exibe as notas fixadas e não fixadas, cada qual em sua seção.
        // Removemos qualquer lógica anterior de sortedNotes que estava associada.
        List {
            // Seção de notas fixadas
            if !store.pinnedNotes.isEmpty {
                Section("Fixadas") {
                    ForEach(store.pinnedNotes, id: \.id) { note in
                        NoteRow(
                            note: note,
                            isSelected: note.id == store.selectedNote?.id
                        )
                        .environmentObject(store)
                    }
                }
            }
            
            // Seção de notas não fixadas
            Section("Outras") {
                ForEach(store.unpinnedNotes, id: \.id) { note in
                    NoteRow(
                        note: note,
                        isSelected: note.id == store.selectedNote?.id
                    )
                    .environmentObject(store)
                }
            }
        }
        .listStyle(.plain)
        #if os(macOS)
        .onDeleteCommand {
            if let selected = store.selectedNote {
                store.deleteNote(selected)
            }
        } #endif
        .scrollContentBackground(.hidden)
        .background(Color("EditorBackground"))
        .environment(\.defaultMinListRowHeight, 0)
        .environment(\.defaultMinListHeaderHeight, 0)
    }
}

#Preview {
    ContentView()
        .environmentObject(NotesStore(context: PersistenceController.shared.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .frame(width: 1200, height: 700)
}

