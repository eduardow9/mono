import SwiftUI

// MARK: - FolderListView
struct FolderListView: View {
    @Binding var folders: [FolderEntity]
    @Binding var expandedFolders: Set<UUID>
    @Binding var selectedFolder: FolderEntity?
    var showFoldersHeader: Bool
    @Binding var selectedLabelID: UUID?
    @EnvironmentObject var store: NotesStore

    // Versão temporária sem usar isSystem
    private var orderedFolders: [FolderEntity] {
        var favoritos: [FolderEntity] = []
        var normais: [FolderEntity] = []

        // Ignora as pastas especiais do sistema por nome
        for folder in folders where folder.parentFolder == nil &&
                                  folder.name != "Todas as notas" &&
                                  folder.name != "Apagadas" {
            if folder.isFavorite {
                favoritos.append(folder)
            } else {
                normais.append(folder)
            }
        }

        return favoritos + normais
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(orderedFolders, id: \.self) { folder in
                    #if os(macOS)
                    FolderRowView(
                        folder: folder,
                        expandedFolders: $expandedFolders,
                        selectedFolder: $selectedFolder,
                        allFolders: folders
                    )
                    #else
                    // iOS: mostre apenas o nome da pasta
                    Text(folder.name ?? "")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFolder = folder
                            selectedLabelID = nil
                        }
                    #endif
                }

                // Aqui vamos passar apenas o selectedLabelID, não o argumento 'labels'
                LabelListView(selectedLabelID: $selectedLabelID)
            }
            .animation(.easeInOut(duration: 0.12), value: folders)
        }
    }
}
