import SwiftUI
import CoreData
import Combine

#if os(macOS)
import AppKit

extension NSColor {
    static var labelCompat: NSColor { .labelColor }
}
#else
import UIKit
typealias UXFont = UIFont
typealias UXColor = UIColor
extension UIColor {
    static var labelCompat: UIColor { .label }
}
#endif

class NotesStore: ObservableObject {
    let context: NSManagedObjectContext
    @Published var notes: [NoteEntity] = []
    @Published var folders: [FolderEntity] = []
    @Published var selectedNote: NoteEntity?
    @Published var selectedFolder: FolderEntity?
    @Published var editingFolder: FolderEntity?
    @Published var selectedNotes: Set<NoteEntity> = []
    @Published var trashedNotes: [NoteEntity] = []
    @Published var archivedNotes: [NoteEntity] = []
    struct LabelTag: Identifiable, Hashable {
        let id = UUID()
        var name: String
        /// Tint shown in the label list; defaults to accentColor
        var color: Color = .accentColor
    }

    @Published var tags: [LabelTag] = []
    @Published var allNotesFolder: FolderEntity?
    @Published var trashFolder: FolderEntity?
    @Published var archivedFolder: FolderEntity?
    private var notePromotionTimer: Timer?
    private var noteBeingEdited: UUID?
    private var saveTimer: Timer?
    var pinnedNotes: [NoteEntity] {
        notes.filter { $0.isPinned }
    }
    var unpinnedNotes: [NoteEntity] {
        notes.filter { !$0.isPinned }
    }
    /// Notas visíveis de acordo com a pasta selecionada
    var filteredNotes: [NoteEntity] {
        guard let folder = selectedFolder else {          // Nenhuma pasta = todas
            return notes
        }
        switch folder.name {
        case "Todas as notas":   return notes                       // todas
        case "Arquivadas":       return archivedNotes
        case "Apagadas":         return trashedNotes
        default:                 return notes.filter { $0.folder == folder }
        }
    }
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchNotes()
        fetchFolders()
        setupSpecialFolders()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHashtagDetected),
            name: .hashtagDetected,
            object: nil
        )
    }
    
    func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.savePendingChanges()
        }
    }
    
    func savePendingChanges() {
        do {
            try context.save()
        } catch {
            print("Erro ao salvar contexto: \(error)")
        }
    }
    
    func addOrUpdateTag(_ tagName: String) {
        // Verificar se já existe tag com este nome
        let normalizedName = tagName.hasPrefix("#") ? tagName : "#\(tagName)"
        
        // Verificar se já existe essa tag
        if !tags.contains(where: { $0.name == normalizedName }) {
            let newTag = LabelTag(name: tagName)
            // Programar a atualização para o próximo ciclo de execução
            DispatchQueue.main.async {
                self.tags.append(newTag)
                self.objectWillChange.send()
            }
        }
    }
    @objc func handleHashtagDetected(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let tagName = userInfo["tagName"] as? String {
            // Programar para o próximo ciclo de execução
            DispatchQueue.main.async {
                self.addOrUpdateTag(tagName)
            }
        }
    }
    private func setupSpecialFolders() {
        let allNotesRequest: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
        allNotesRequest.predicate = NSPredicate(format: "name == %@", "Todas as notas")
        let trashRequest: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
        trashRequest.predicate = NSPredicate(format: "name == %@", "Apagadas")
        let archivedRequest: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
        archivedRequest.predicate = NSPredicate(format: "name == %@", "Arquivadas")
        do {
            let allNotesFolders = try context.fetch(allNotesRequest)
            let trashFolders = try context.fetch(trashRequest)
            let archivedFolders = try context.fetch(archivedRequest)
            if let folder = allNotesFolders.first {
                allNotesFolder = folder
            } else {
                let newFolder = FolderEntity(context: context)
                newFolder.id = UUID()
                newFolder.name = "Todas as notas"
                allNotesFolder = newFolder
            }
            if let folder = trashFolders.first {
                trashFolder = folder
            } else {
                let newFolder = FolderEntity(context: context)
                newFolder.id = UUID()
                newFolder.name = "Apagadas"
                trashFolder = newFolder
            }
            if let folder = archivedFolders.first {
                archivedFolder = folder
            } else {
                let newFolder = FolderEntity(context: context)
                newFolder.id = UUID()
                newFolder.name = "Arquivadas"
                archivedFolder = newFolder
            }
            try context.save()
            fetchFolders()
        } catch {
            print("Erro ao configurar pastas especiais: \(error)")
        }
        fetchTrashedNotes()
        fetchArchivedNotes()
    }
    func fetchNotes() {
        let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isTrashed == false AND isArchived == false")
        do {
            notes = try context.fetch(request)
        } catch {
            print("Erro ao buscar notas: \(error)")
        }
    }
    func fetchTrashedNotes() {
        let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isTrashed == true")
        do {
            trashedNotes = try context.fetch(request)
        } catch {
            print("Erro ao buscar notas apagadas: \(error)")
        }
    }
    func fetchArchivedNotes() {
        let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == true")
        do {
            archivedNotes = try context.fetch(request)
        } catch {
            print("Erro ao buscar notas arquivadas: \(error)")
        }
    }
    func fetchFolders() {
        let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \FolderEntity.isFavorite, ascending: false),
            NSSortDescriptor(keyPath: \FolderEntity.name, ascending: true)
        ]
        do {
            folders = try context.fetch(request)
            allNotesFolder = folders.first(where: { $0.name == "Todas as notas" })
            trashFolder = folders.first(where: { $0.name == "Apagadas" })
            archivedFolder = folders.first(where: { $0.name == "Arquivadas" })
        } catch {
            print("Erro ao buscar pastas: \(error)")
        }
    }
    @discardableResult
    func addFolder(name: String, parent: FolderEntity? = nil) -> FolderEntity {
        let newFolder = FolderEntity(context: context)
        newFolder.id = UUID()
        newFolder.name = name
        newFolder.parentFolder = parent
        newFolder.isFavorite = false
        do {
            try context.save()
            fetchFolders()
        } catch {
            print("Erro ao criar pasta: \(error)")
        }
        return newFolder
    }
    func deleteFolder(_ folder: FolderEntity) {
        if folder.isSystemFolder ||
           folder.name == "Todas as notas" ||
           folder.name == "Apagadas" ||
           folder.name == "Arquivadas" {
            return
        }
        if let subfolders = folder.subfolders?.allObjects as? [FolderEntity] {
            for child in subfolders {
                deleteFolder(child)
            }
        }
        if selectedFolder?.objectID == folder.objectID {
            let parentLevel = folder.parentFolder != nil ? folder.parentFolder! : nil
            let sameLevelFolders = folders.filter { $0.parentFolder == parentLevel && !$0.isSystemFolder && $0.id != folder.id }
            if let index = sameLevelFolders.firstIndex(where: { $0.id == folder.id }) {
                if index < sameLevelFolders.count - 1 {
                    selectedFolder = sameLevelFolders[index + 1]
                } else if index > 0 {
                    selectedFolder = sameLevelFolders[index - 1]
                } else {
                    selectedFolder = parentLevel ?? allNotesFolder
                }
            } else {
                selectedFolder = allNotesFolder
            }
        }
        if let index = folders.firstIndex(where: { $0.objectID == folder.objectID }) {
            folders.remove(at: index)
        }
        context.delete(folder)
        do {
            try context.save()
            fetchFolders()
        } catch {
            print("Erro ao excluir pasta: \(error)")
        }
    }
    func moveFolder(from source: IndexSet, to destination: Int) {
        folders.move(fromOffsets: source, toOffset: destination)
    }
    func createNewNote() {
         let newNote = NoteEntity(context: context)
         newNote.id = UUID()
         newNote.title = ""
         newNote.content = ""
         
         // Criar o NSAttributedString com a fonte correta
         let attrs: [NSAttributedString.Key: Any] = [
             .font: UXFont.systemFont(ofSize: 16),
             .foregroundColor: UXColor.labelCompat
         ]
         let attributedString = NSAttributedString(string: "", attributes: attrs)
         newNote.formattedContent = attributedString
         newNote.dateModified = Date()
         newNote.isPinned = false
         newNote.isTrashed = false
         newNote.isArchived = false
        // Associar à pasta selecionada, se for uma pasta normal
        if let selectedFolder = selectedFolder,
           selectedFolder != allNotesFolder &&
           selectedFolder != trashFolder &&
           selectedFolder != archivedFolder {
            newNote.folder = selectedFolder
        }
        notes.insert(newNote, at: 0)
        selectedNotes.removeAll()
        selectedNote = newNote
        selectedNotes.insert(newNote)
        do {
            try context.save()
            // Notificar mudança imediatamente
            self.objectWillChange.send()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .focusEditor, object: nil)
            }
        } catch {
            print("Erro ao criar nova nota: \(error)")
        }
    }
    func scheduleNotePromotionAfterEditing(_ note: NoteEntity) {
        // Cancelar qualquer timer anterior
        notePromotionTimer?.invalidate()
        
        // Verificar se a nota já está no topo
        if let firstNote = notes.first, firstNote.id == note.id {
            return
        }
        
        // Guardar o ID da nota sendo editada
        noteBeingEdited = note.id
        
        // Agendar promoção
        notePromotionTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self,
                  let noteID = self.noteBeingEdited,
                  let note = self.notes.first(where: { $0.id == noteID }) else {
                return
            }
            
            DispatchQueue.main.async {
                if let index = self.notes.firstIndex(where: { $0.id == noteID }), index > 0 {
                    self.notes.remove(at: index)
                    self.notes.insert(note, at: 0)
                    self.objectWillChange.send()
                }
            }
            
            self.noteBeingEdited = nil
        }
    }
    func deleteNote(_ note: NoteEntity) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes.remove(at: index)
        }
        
        if let index = archivedNotes.firstIndex(where: { $0.id == note.id }) {
            archivedNotes.remove(at: index)
        }
        
        note.isTrashed = true
        note.isArchived = false
        
        trashedNotes.append(note)
        
        if selectedNote?.id == note.id {
            updateNoteSelectionAfterDelete(note)
        }
        
        do {
            try context.save()
        } catch {
            print("Erro ao mover nota para lixeira: \(error)")
        }
    }

    private func updateNoteSelectionAfterDelete(_ note: NoteEntity) {
        if let currentIndex = filteredNotes.firstIndex(where: { $0.id == note.id }) {
            let filteredNotesBeforeDeletion = filteredNotes
            if currentIndex < filteredNotesBeforeDeletion.count - 1 {
                selectedNote = filteredNotesBeforeDeletion[currentIndex + 1]
            } else if currentIndex > 0 && !filteredNotesBeforeDeletion.isEmpty {
                selectedNote = filteredNotesBeforeDeletion[currentIndex - 1]
            } else {
                selectedNote = nil
            }
            selectedNotes.removeAll()
            if let selected = selectedNote {
                selectedNotes.insert(selected)
            }
        }
    }
    func archiveNote(_ note: NoteEntity) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes.remove(at: index)
        }
        note.isArchived = true
        note.isTrashed = false
        archivedNotes.append(note)
        if selectedNote?.id == note.id {
            updateNoteSelectionAfterDelete(note)
        }
        do {
            try context.save()
        } catch {
            print("Erro ao arquivar nota: \(error)")
        }
    }
    func unarchiveNote(_ note: NoteEntity) {
        if let index = archivedNotes.firstIndex(where: { $0.id == note.id }) {
            archivedNotes.remove(at: index)
        }
        note.isArchived = false
        note.isTrashed = false
        notes.append(note)
        do {
            try context.save()
            fetchNotes()
        } catch {
            print("Erro ao restaurar nota arquivada: \(error)")
        }
    }
    func permanentlyDeleteNote(_ note: NoteEntity) {
        if let index = trashedNotes.firstIndex(where: { $0.id == note.id }) {
            trashedNotes.remove(at: index)
        }
        if let index = archivedNotes.firstIndex(where: { $0.id == note.id }) {
            archivedNotes.remove(at: index)
        }
        if selectedNote?.id == note.id {
            if let currentIndex = trashedNotes.firstIndex(where: { $0.id == note.id }) {
                if currentIndex < trashedNotes.count - 1 {
                    selectedNote = trashedNotes[currentIndex + 1]
                } else if currentIndex > 0 {
                    selectedNote = trashedNotes[currentIndex - 1]
                } else {
                    selectedNote = nil
                }
            }
        }
        selectedNotes.remove(note)
        context.delete(note)
        do {
            try context.save()
        } catch {
            print("Erro ao excluir nota permanentemente: \(error)")
        }
    }
    func restoreNote(_ note: NoteEntity) {
        if let index = trashedNotes.firstIndex(where: { $0.id == note.id }) {
            trashedNotes.remove(at: index)
        }
        note.isTrashed = false
        note.isArchived = false
        notes.append(note)
        do {
            try context.save()
            fetchNotes()
        } catch {
            print("Erro ao restaurar nota: \(error)")
        }
    }
    func deleteMultipleNotes(_ notesToDelete: Set<NoteEntity>) {
        let orderedNotes = filteredNotes.filter { notesToDelete.contains($0) }
        if let firstNote = orderedNotes.first,
           let firstIndex = filteredNotes.firstIndex(where: { $0.id == firstNote.id }) {
            let nextIndex = firstIndex < filteredNotes.count - orderedNotes.count ? firstIndex + 1 : firstIndex - 1
            let nextNote = nextIndex >= 0 && nextIndex < filteredNotes.count ? filteredNotes[nextIndex] : nil
            for note in notesToDelete {
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes.remove(at: index)
                }
                if let index = archivedNotes.firstIndex(where: { $0.id == note.id }) {
                    archivedNotes.remove(at: index)
                }
                note.isTrashed = true
                note.isArchived = false
                trashedNotes.append(note)
            }
            if notesToDelete.contains(where: { $0.id == selectedNote?.id }) {
                selectedNote = nextNote
            }
            selectedNotes.removeAll()
            if let selectedNote = selectedNote {
                selectedNotes.insert(selectedNote)
            }
            do {
                try context.save()
            } catch {
                print("Erro ao mover múltiplas notas para lixeira: \(error)")
            }
        }
    }
    func archiveMultipleNotes(_ notesToArchive: Set<NoteEntity>) {
        let orderedNotes = filteredNotes.filter { notesToArchive.contains($0) }
        if let firstNote = orderedNotes.first,
           let firstIndex = filteredNotes.firstIndex(where: { $0.id == firstNote.id }) {
            let nextIndex = firstIndex < filteredNotes.count - orderedNotes.count ? firstIndex + 1 : firstIndex - 1
            let nextNote = nextIndex >= 0 && nextIndex < filteredNotes.count ? filteredNotes[nextIndex] : nil
            for note in notesToArchive {
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes.remove(at: index)
                }
                note.isArchived = true
                note.isTrashed = false
                archivedNotes.append(note)
            }
            if notesToArchive.contains(where: { $0.id == selectedNote?.id }) {
                selectedNote = nextNote
            }
            selectedNotes.removeAll()
            if let selectedNote = selectedNote {
                selectedNotes.insert(selectedNote)
            }
            do {
                try context.save()
            } catch {
                print("Erro ao arquivar múltiplas notas: \(error)")
            }
        }
    }
    func togglePinForNotes(_ notesToToggle: Set<NoteEntity>) {
        let pinnedCount = notesToToggle.filter { $0.isPinned }.count
        let shouldPin = pinnedCount < notesToToggle.count / 2
        for note in notesToToggle {
            note.isPinned = shouldPin
            note.dateModified = Date()
        }
        do {
            try context.save()
            self.objectWillChange.send()
        } catch {
            print("Erro ao alterar status de fixação: \(error)")
        }
    }
    func moveNotesToFolder(_ notesToMove: Set<NoteEntity>, folder: FolderEntity?) {
        for note in notesToMove {
            note.folder = folder
            note.dateModified = Date()
        }
        do {
            try context.save()
            self.objectWillChange.send()
        } catch {
            print("Erro ao mover notas para pasta: \(error)")
        }
    }
    func emptyTrash() {
        for note in trashedNotes {
            context.delete(note)
        }
        trashedNotes.removeAll()
        if selectedFolder == trashFolder {
            selectedNote = nil
            selectedNotes.removeAll()
        }
        do {
            try context.save()
        } catch {
            print("Erro ao esvaziar lixeira: \(error)")
        }
    }
    func getTitleFromContent(_ content: String?) -> String {
        guard let content = content, !content.isEmpty else {
            return "Nova nota"
        }
        let lines = content.components(separatedBy: .newlines)
        let firstLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "Nova nota"
        let trimmedLine = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLine.count > 30 {
            return String(trimmedLine.prefix(30)) + "..."
        }
        return trimmedLine
    }
    func stopFolderEditing() {
        editingFolder = nil
    }
    func cancelNotePromotion() {
        notePromotionTimer?.invalidate()
        notePromotionTimer = nil
        noteBeingEdited = nil
    }
}
