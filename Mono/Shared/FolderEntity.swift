import SwiftUI


extension FolderEntity {
    /// Conjunto de nomes reservados para pastas especiais do sistema.
    /// ‑ Se precisar adicionar outro nome depois, basta incluir aqui.
    static let systemFolderNames: Set<String> = [
        "Todas as notas",
        "Apagadas",
        "Arquivadas"
    ]

    var totalNoteCount: Int {
        let notesCount = (notes?.count ?? 0)
        
        // Se não houver subpastas, apenas retornar a contagem de notas
        guard let subfolders = subfolders?.allObjects as? [FolderEntity], !subfolders.isEmpty else {
            return notesCount
        }
        
        // Somar contagem de notas em subpastas
        let subfoldersCount = subfolders.reduce(0) { sum, folder in
            sum + folder.totalNoteCount
        }
        
        return notesCount + subfoldersCount
    }
    
    enum SystemFolder: String, CaseIterable {
        case allNotes     = "Todas as notas"
        case archived     = "Arquivadas"
        case trash        = "Apagadas"
    }

    var systemKind: SystemFolder? {
        SystemFolder(rawValue: name ?? "")
    }

    /// `true` se esta pasta é uma das pastas internas (“Todas as notas”, “Arquivadas”, “Apagadas”)
    var isSystemFolder: Bool {
        systemKind != nil
    }
}
