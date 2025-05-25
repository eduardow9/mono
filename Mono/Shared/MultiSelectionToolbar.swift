import SwiftUI

struct MultiSelectionToolbar: View {
    @EnvironmentObject var store: NotesStore
    @State private var showFolderMenu = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(store.selectedNotes.count) notas selecionadas")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    store.togglePinForNotes(store.selectedNotes)
                } label: {
                    Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                        .foregroundColor(.primary)
                }
                .help(isPinned ? "Desafixar notas" : "Fixar notas")
                
                Button {
                    showFolderMenu = true
                } label: {
                    Image(systemName: "folder")
                        .foregroundColor(.primary)
                }
                .help("Mover para pasta")
                .popover(isPresented: $showFolderMenu) {
                    FolderSelectionMenu()
                        .frame(width: 250, height: 300)
                        .environmentObject(store)
                }
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.primary)
                }
                .help("Excluir notas")
                .alert("Excluir notas?", isPresented: $showDeleteConfirmation) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Excluir", role: .destructive) {
                        store.deleteMultipleNotes(store.selectedNotes)
                    }
                } message: {
                    Text("Você está prestes a excluir \(store.selectedNotes.count) notas. Esta ação não pode ser desfeita.")
                }
            }
            
            Divider()
                .frame(height: 20)
            
            Button {
                store.selectedNotes.removeAll()
            } label: {
                Text("Cancelar")
                    .foregroundColor(.primary)
            }
            .padding(.trailing)
        }
        .frame(height: 40)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private var isPinned: Bool {
        let pinnedCount = store.selectedNotes.filter { $0.isPinned }.count
        return pinnedCount > store.selectedNotes.count / 2
    }
}
