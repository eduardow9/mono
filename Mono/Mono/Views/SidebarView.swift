import SwiftUI
import AppKit

struct SidebarView: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedFolders: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var selectedLabelID: UUID? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Padding superior
            Spacer().frame(height: 25)
            
            // Pasta "Todas as Notas" - renomeada para "Notas" sem ícone
            if let allNotesFolder = store.allNotesFolder {
                HStack(spacing: 0) {
                    // Espaço para manter alinhamento com outras pastas
                    Spacer()
                        .frame(width: 20)
                    
                    // Nome da pasta "Notas" simples
                    Text("Notas")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(store.selectedFolder?.id == allNotesFolder.id ? .white : Color("TextPrimary"))
                    
                    Spacer()
                    
                    // Contador de notas
                    Text("\(store.notes.count)")
                        .font(.system(size: 14, weight: .regular))
                        .frame(minWidth: 22, alignment: .trailing)
                        .foregroundColor(store.selectedFolder?.id == allNotesFolder.id ? .white : Color("TextSecondary"))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(store.selectedFolder?.id == allNotesFolder.id ? Color.monoAccent : Color.clear)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    store.selectedFolder = allNotesFolder
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Seção de Pastas
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Pastas")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.leading, 2)
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                        .foregroundColor(Color("TextSecondary"))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Filtrar apenas pastas normais (não do sistema)
                let normalFolders = store.folders.filter { folder in
                    // Excluir pastas do sistema
                    folder.isSystem == false &&
                    // Excluir todas as pastas especiais por nome
                    folder.name != "Todas as notas" &&
                    folder.name != "Apagadas" &&
                    folder.name != "Arquivadas" &&
                    // Excluir também por ID para garantir
                    folder.id != store.allNotesFolder?.id &&
                    folder.id != store.trashFolder?.id &&
                    folder.id != store.archivedFolder?.id
                }
                
                // Pastas normais seguido imediatamente pelas etiquetas
                ForEach(normalFolders.filter { $0.parentFolder == nil }, id: \.self) { folder in
                    FolderRowView(
                        folder: folder,
                        expandedFolders: $expandedFolders,
                        selectedFolder: $store.selectedFolder,
                        allFolders: normalFolders
                    )
                }
                .animation(.easeInOut(duration: 0.12), value: store.folders)
                
                Divider()
                    .padding(.vertical, 8)
                    .colorInvert()
                
                // Seção de etiquetas LOGO APÓS as pastas
                Text("Etiquetas")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.leading, 2)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color("TextSecondary"))
                
                // Tags em layout horizontal
                HorizontalLabelView(labels: store.tags, selectedLabelID: $selectedLabelID)
                    .padding(.bottom, 10)
                Spacer() // Empurra as pastas especiais para o final
                
                // Botão para adicionar nova pasta
                
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                        .frame(width: 20, alignment: .center)
                        .foregroundColor(Color("TextPrimary"))
                    
                    Text("Nova pasta")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("TextPrimary"))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    let new = store.addFolder(name: "Nova pasta")
                    store.editingFolder = new
                    store.selectedFolder = new
                }
            
                Divider()
                    .padding(.vertical, 5)
                        
                
                // Pasta "Arquivadas" - movida para o final
                if let archivedFolder = store.archivedFolder {
                    SpecialFolderRow(
                        folder: archivedFolder,
                        icon: "archivebox",
                        displayName: "Arquivadas",
                        isSelected: store.selectedFolder?.id == archivedFolder.id
                    )
                }
                
                // Pasta "Lixeira" - movida para o final após arquivadas
                if let trashFolder = store.trashFolder {
                    SpecialFolderRow(
                        folder: trashFolder,
                        icon: "trash",
                        displayName: "Apagadas",
                        isSelected: store.selectedFolder?.id == trashFolder.id
                    )
                    .contextMenu {
                        Button("Esvaziar Lixeira") {
                            store.emptyTrash()
                        }
                    }
                }
            }
            
            Spacer().frame(height: 16)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 14) // Padding esquerdo e direito de TODO o Sidebar
        .background(Color.clear)
        // Encerra a edição de pasta se o usuário clicar em qualquer área do sidebar
        .simultaneousGesture(
            TapGesture().onEnded {
                if store.editingFolder != nil {
                    store.stopFolderEditing()
                }
            }
        )
        .alert("Deletar pasta?", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Apagar", role: .destructive) {
                if let folder = store.selectedFolder, folder.isSystem == false, folder.managedObjectContext != nil {
                    folder.notes = nil
                    folder.subfolders = nil
                    store.deleteFolder(folder)
                    store.selectedFolder = nil
                }
            }
        } message: {
            Text("Tem certeza de que deseja apagar esta pasta?")
        }

    }
}

// Layout horizontal para as etiquetas - Sem bullets
struct HorizontalLabelView: View {
    let labels: [NotesStore.LabelTag]
    @Binding var selectedLabelID: UUID?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(labels) { label in
                    TagPill(label: label, isSelected: selectedLabelID == label.id) {
                        selectedLabelID = label.id
                    }
                }
            }
            .padding(.horizontal, 14)
        }
    }
}

// Pílula de tag - Sem bullets
struct TagPill: View {
    let label: NotesStore.LabelTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label.name)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : Color("TextPrimary"))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.monoAccent : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - SpecialFolderRow
struct SpecialFolderRow: View {
    var folder: FolderEntity
    var icon: String
    var displayName: String  // Nome de exibição personalizado
    var isSelected: Bool
    @EnvironmentObject var store: NotesStore
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : Color("TextPrimary"))
                .frame(width: 20, alignment: .center)
            
            Text(displayName)  // Usando o nome de exibição em vez de folder.name
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(isSelected ? .white : Color("TextPrimary"))
            
            Spacer()
            
            // Contador de notas
            if folder == store.allNotesFolder {
                Text("\(store.notes.count)")
                    .font(.system(size: 14, weight: .regular))
                    .frame(minWidth: 22, alignment: .trailing)
                    .foregroundColor(isSelected ? .white : Color("TextSecondary"))
                    .id(UUID()) // Forçar atualização
            } else if folder == store.trashFolder {
                Text("\(store.trashedNotes.count)")
                    .font(.system(size: 14, weight: .regular))
                    .frame(minWidth: 22, alignment: .trailing)
                    .foregroundColor(isSelected ? .white : Color("TextSecondary"))
                    .id(UUID()) // Forçar atualização
            } else if folder == store.archivedFolder {
                Text("\(store.archivedNotes.count)")
                    .font(.system(size: 14, weight: .regular))
                    .frame(minWidth: 22, alignment: .trailing)
                    .foregroundColor(isSelected ? .white : Color("TextSecondary"))
                    .id(UUID()) // Forçar atualização
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.monoAccent : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectedFolder = folder
            
            // 5. Limpar seleção de nota ao trocar de pasta
            if store.selectedNote != nil {
                store.selectedNote = nil
                store.selectedNotes.removeAll()
            }
        }
    }
}

// MARK: - FolderRowView
struct FolderRowView: View {
    let folder: FolderEntity
    @Binding var expandedFolders: Set<UUID>
    @Binding var selectedFolder: FolderEntity?
    let allFolders: [FolderEntity]
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var store: NotesStore
    @FocusState private var isFocused: Bool
    @State private var showDeleteConfirmation = false

    var isExpanded: Bool {
        guard let id = folder.id else { return false }
        return expandedFolders.contains(id)
    }
    
    var isSelected: Bool {
        folder.id == selectedFolder?.id
    }
    
    // Nova propriedade para verificar se a pasta está selecionada mas é seleção secundária
    // (quando existe uma nota selecionada também)
    var isSecondarySelection: Bool {
        isSelected && store.selectedNote != nil && store.selectedFolder?.id == folder.id
    }
    
    var children: [FolderEntity] {
        // Filtrar subpastas excluindo pastas do sistema
        allFolders.filter { $0.parentFolder == folder && $0.isSystem == false }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Group {
                    if !children.isEmpty {
                        // Seta de expansão
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                if let id = folder.id {
                                    if isExpanded {
                                        expandedFolders.remove(id)
                                    } else {
                                        expandedFolders.insert(id)
                                    }
                                }
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .frame(width: 20, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                    } else {
                        // Espaço para alinhar verticalmente com outras pastas
                        Spacer()
                            .frame(width: 20, height: 28)
                    }
                }
                
                // Ícone da pasta como favorito
                Image(systemName: folder.isFavorite ? "circle.fill" : "circle")
                    .onTapGesture {
                        withAnimation {
                            if let index = store.folders.firstIndex(of: folder) {
                                store.folders.remove(at: index)
                                folder.isFavorite.toggle()
                                store.folders.insert(folder, at: store.folders.prefix(while: { $0.isFavorite }).count)
                                try? folder.managedObjectContext?.save()
                                folder.objectWillChange.send()
                            }
                        }
                    }
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(
                        isSelected
                            ? (isSecondarySelection ? .white : .white)
                            : (folder.isFavorite ? Color.monoAccent : Color("TextSecondary"))
                    )

                
                // Nome da pasta
                if store.editingFolder == folder {
                    TextField("Nova pasta", text: Binding(
                        get: { folder.name ?? "Nova pasta" },
                        set: {
                            folder.name = $0
                            try? folder.managedObjectContext?.save()
                        }
                    ))
                    .focused($isFocused)
                    .tint(isSelected ? .primary : Color("TextPrimary"))
                    .onAppear {
                        isFocused = true
                    }
                    .onSubmit {
                        store.stopFolderEditing()
                        isFocused = false
                    }
                    .onChange(of: isFocused) { oldValue, newValue in
                        if !newValue {
                            store.stopFolderEditing()
                        }
                    }
                    .font(Font.system(size: 14, weight: .regular))
                    .foregroundColor(isSelected ? .white : Color("TextPrimary"))
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(height: 24)
                    .background(Color.clear) // Remover o fundo branco
                    .onTapGesture { } // Impede que o clique no TextField dispare o detector externo
                } else {
                    Text(folder.name ?? "Sem nome")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(isSelected ? .white : Color("TextPrimary"))
                        .onTapGesture {
                            if selectedFolder == folder {
                                store.editingFolder = folder
                            } else {
                                selectedFolder = folder
                                store.selectedFolder = folder
                                store.editingFolder = nil
                            }
                        }
                }
                
                Spacer() // Empurra o contador de notas para a direita
                
                // Contador de notas
                Text("\(store.notes.filter { $0.folder == folder && !$0.isTrashed && !$0.isArchived }.count)")
                    .font(.system(size: 14, weight: .regular))
                    .frame(minWidth: 22, alignment: .trailing)
                    .foregroundColor(isSelected ? .white : Color("TextSecondary"))
                    .padding(.trailing, 8) // Padding horizontal que empurra o contador de notas
                    .frame(height: 23) // Padding vertical das pastas
                    .id(UUID()) // Forçar atualização
            }
            .padding(.vertical, 4) // Aumentado de 2 para 4
            .padding(.leading, 2) // Padding horizontal que empurra o icone da pasta
            .listRowBackground(Color.clear)
            .background(
                ZStack(alignment: .center) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            // Removida a condição que verifica isSecondarySelection
                            // Agora sempre usamos Color.monoAccent para garantir consistência
                            .fill(Color.monoAccent)
                            .frame(height: 28)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedFolder = folder
                store.selectedFolder = folder
                
                // 5. Limpar seleção de nota ao trocar de pasta
                if store.selectedNote != nil {
                    store.selectedNote = nil
                    store.selectedNotes.removeAll()
                }
            }
            .contextMenu {
                Button("Nova subpasta") {
                    let new = store.addFolder(name: "Nova subpasta")
                    new.parentFolder = folder
                    selectedFolder = new
                    store.selectedFolder = new
                    store.editingFolder = new
                    expandedFolders.insert(folder.id!)
                    try? folder.managedObjectContext?.save()
                }
                
                if folder.isSystem == false {
                    Button("Apagar pasta", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .alert("Deletar pasta?", isPresented: $showDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Apagar", role: .destructive) {
                    if folder.isSystem == false {
                        store.deleteFolder(folder)
                    }
                }
            } message: {
                Text("Tem certeza que deseja apagar esta pasta?")
            }
            
            // Subpastas - Modificado para usar hífen em vez de bullet
            if isExpanded && !children.isEmpty {
                ForEach(children, id: \.self) { child in
                    SubfolderRowView(
                        folder: child,
                        expandedFolders: $expandedFolders,
                        selectedFolder: $selectedFolder,
                        allFolders: allFolders
                    )
                    .padding(.leading, 8) // Subpasta recuada
                    .padding(.vertical, 2) // Espaçamento vertical maior
                }
            }
        }
    }
}

// Subpasta com formato alinhado
struct SubfolderRowView: View {
    let folder: FolderEntity
    @Binding var expandedFolders: Set<UUID>
    @Binding var selectedFolder: FolderEntity?
    let allFolders: [FolderEntity]
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var store: NotesStore
    @FocusState private var isFocused: Bool
    @State private var showDeleteConfirmation = false
    
    var isSelected: Bool {
        folder.id == selectedFolder?.id
    }
    
    // Nova propriedade para verificar se a pasta está selecionada mas é seleção secundária
    var isSecondarySelection: Bool {
        isSelected && store.selectedNote != nil && store.selectedFolder?.id == folder.id
    
    }
    
    var children: [FolderEntity] {
        allFolders.filter { $0.parentFolder == folder && $0.isSystem == false }
    }
    
    var isExpanded: Bool {
        guard let id = folder.id else { return false }
        return expandedFolders.contains(id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                if !children.isEmpty {
                    // Seta de expansão
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            if let id = folder.id {
                                if isExpanded {
                                    expandedFolders.remove(id)
                                } else {
                                    expandedFolders.insert(id)
                                }
                            }
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .frame(width: 20, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                } else {
                    // Espaço para alinhamento ao invés de hífen
                    Spacer()
                        .frame(width: 20, height: 28)
                }
                
                // Nome da pasta
                if store.editingFolder == folder {
                    TextField("Nova pasta", text: Binding(
                        get: { folder.name ?? "Nova pasta" },
                        set: {
                            folder.name = $0
                            try? folder.managedObjectContext?.save()
                        }
                    ))
                    .focused($isFocused)
                    .tint(isSelected ? .white : Color("TextPrimary"))
                    .onAppear {
                        isFocused = true
                    }
                    .onSubmit {
                        store.stopFolderEditing()
                        isFocused = false
                    }
                    .onChange(of: isFocused) { oldValue, newValue in
                        if !newValue {
                            store.stopFolderEditing()
                        }
                    }
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(isSelected ? .white : Color("TextPrimary"))
                    .textFieldStyle(.plain)
                    .frame(height: 24)
                    .background(Color.clear)
                    .onTapGesture { } // Impede que o clique no TextField dispare o detector externo
                } else {
                    Text(folder.name ?? "Sem nome")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(isSelected ? .white : Color("TextPrimary"))
                        .onTapGesture {
                            if selectedFolder == folder {
                                store.editingFolder = folder
                            } else {
                                selectedFolder = folder
                                store.selectedFolder = folder
                                store.editingFolder = nil
                            }
                        }
                }
                
                Spacer()
                
                // Contador de notas
                Text("\(store.notes.filter { $0.folder == folder && !$0.isTrashed && !$0.isArchived }.count)")
                    .font(.system(size: 14, weight: .regular))
                    .frame(minWidth: 22, alignment: .trailing)
                    .foregroundColor(isSelected ? .white : Color("TextSecondary"))
                    .padding(.trailing, 8)
                    .id(UUID()) // Forçar atualização
            }
            .padding(.vertical, 4)
            .background(
                ZStack(alignment: .center) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            // Removida a condição para isSecondarySelection
                            .fill(Color.monoAccent)
                            .frame(height: 28)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedFolder = folder
                store.selectedFolder = folder
                store.editingFolder = nil
                
                // 5. Limpar seleção de nota ao trocar de pasta
                if store.selectedNote != nil {
                    store.selectedNote = nil
                    store.selectedNotes.removeAll()
                }
            }
            .contextMenu {
                Button("Nova subpasta") {
                    let new = store.addFolder(name: "Nova subpasta")
                    new.parentFolder = folder
                    selectedFolder = new
                    store.selectedFolder = new
                    store.editingFolder = new
                    expandedFolders.insert(folder.id!)
                    try? folder.managedObjectContext?.save()
                }
                
                if folder.isSystem == false {
                    Button("Apagar pasta", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .alert("Deletar pasta?", isPresented: $showDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Apagar", role: .destructive) {
                    if folder.isSystem == false {
                        store.deleteFolder(folder)
                    }
                }
            } message: {
                Text("Tem certeza que deseja apagar esta pasta?")
            }
            
            // Subpastas recursivas
            if isExpanded && !children.isEmpty {
                ForEach(children, id: \.self) { child in
                    SubfolderRowView(
                        folder: child,
                        expandedFolders: $expandedFolders,
                        selectedFolder: $selectedFolder,
                        allFolders: allFolders
                    )
                    .padding(.leading, 8)
                    .padding(.vertical, 2) // Espaçamento vertical maior
                }
            }
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(NotesStore(context: PersistenceController.shared.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .frame(width: 1200, height: 700)
}
