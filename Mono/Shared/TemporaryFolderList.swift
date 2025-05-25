import SwiftUI

// Correção temporária para a FolderListView
extension FolderListView {
    // Versão modificada do orderedFolders sem usar isSystem
    private var orderedFoldersFixed: [FolderEntity] {
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
}

