import SwiftUI

struct FolderSelectionMenu: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Selecione uma pasta")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        store.moveNotesToFolder(store.selectedNotes, folder: nil)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "tray")
                            Text("Sem pasta")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    
                    ForEach(store.folders.filter { $0.parentFolder == nil }, id: \.self) { folder in
                        FolderItem(folder: folder, level: 0)
                    }
                }
            }
        }
    }
}

struct FolderItem: View {
    var folder: FolderEntity
    var level: Int
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            store.moveNotesToFolder(store.selectedNotes, folder: folder)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "folder")
                Text(folder.name ?? "Sem nome")
            }
            .padding(.leading, CGFloat(level * 16))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(BorderlessButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 4)
        
        if let subfolders = folder.subfolders?.allObjects as? [FolderEntity], !subfolders.isEmpty {
            ForEach(subfolders.sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.self) { subfolder in
                FolderItem(folder: subfolder, level: level + 1)
            }
        }
    }
}


