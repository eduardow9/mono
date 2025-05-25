import SwiftUI
#if os(macOS)
import AppKit
#endif

struct PinnedNotesSection: View {
    let pinned: [NoteEntity]
    @EnvironmentObject var store: NotesStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            notesList
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var header: some View {
        Group {
            if !pinned.isEmpty {
                Text("Fixadas")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextSecondary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var notesList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(pinned.filter { $0.id != nil }, id: \.id) { note in
                NoteCard(note: note)
                    .id(note.id)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: store.notes)
        .padding(.horizontal, 20)
    }
    
    private func NoteCard(note: NoteEntity) -> some View {
        let isSelected = store.selectedNotes.contains(note) || store.selectedNote?.id == note.id
        
        return ZStack(alignment: .bottom) {
            // Background com cantos arredondados
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color("SidebarColor") : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .overlay(
                    // Adiciona uma borda mais escura quando selecionado
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color("TextSecondary").opacity(0.2) : Color.clear, lineWidth: 1)
                )
                // Barra inferior para indicar seleção — top reto, cantos inferiores arredondados
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(Color("AccentColor"))
                            .frame(height: 4)
                            .padding(.horizontal, 1)                 // recuo 1 pt para não vazar
                            .mask(BottomRoundedCorners(radius: 12)) // recorta só cantos de baixo
                    }
                }
            
            // Conteúdo da nota
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    // Remove o prefixo [TRASH] se existir
                    let displayTitle = formatTitle(note.title ?? "Untitled")
                    
                    Text(displayTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if note.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color("TextSecondary"))
                    }
                }
                .padding(.top, 8)
                
                // Mostra a data da última modificação formatada de forma inteligente
                Text(formattedLastModified(date: note.dateModified))
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.top, 4)
                
                if let content = note.content,
                   !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Mostra apenas a segunda linha em diante como preview
                    Text(note.isLocked ? "Nota bloqueada" : getContentPreview(content))
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextSecondary"))
                        .lineLimit(2)
                        .padding(.top, 4)
                        .padding(.bottom, isSelected ? 8 : 11)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)         // mesmo espaçamento vertical usado em GroupedNotesSection
        }
        .environmentObject(store)
        // Espaço externo: 2 pt nas laterais, 4 pt em cima/baixo (mesmo de GroupedNotesSection)
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
#if os(iOS)
        .background(NavigationLink(value: note) { EmptyView() }.opacity(0))
#endif
        .frame(height: 110)
#if os(macOS)
        .onTapGesture {
            if let tv = textViewGlobal,
               tv.window?.firstResponder === tv {
                tv.window?.makeFirstResponder(nil)   // solta foco do editor
            }
            handleSelection(for: note)
        }
#else
#endif
        #if os(macOS)
        .onDeleteCommand {
            if store.selectedNotes.contains(note) {
                for selectedNote in store.selectedNotes {
                    store.deleteNote(selectedNote)
                }
                store.selectedNotes.removeAll()
            } else {
                store.deleteNote(note)
            }
        }
        #endif
        .transition(.move(edge: .leading).combined(with: .opacity))
        .frame(maxWidth: .infinity)
    }
    
    // Função para formatar a data de modificação de forma inteligente
    private func formattedLastModified(date: Date?) -> String {
        guard let date = date else { return "" }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day, .month, .year], from: date, to: now)
        
        // Se for menos de 1 minuto (ou seja, nova nota), mostra apenas a hora
        if components.minute == 0, components.hour == 0, components.day == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm" // Formato 24 horas
            return formatter.string(from: date)
        }
        
        // Minutos atrás (menos de 1 hora)
        if let minutes = components.minute, components.hour == 0, components.day == 0 {
            return "\(minutes) minutos atrás"
        }
        
        // Horas atrás (menos de 1 dia)
        if let hours = components.hour, components.day == 0 {
            return "\(hours) horas atrás"
        }
        
        // Para datas mais antigas, usar formato de data abreviado
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        
        // Se for este ano, mostrar apenas dia e mês
        if components.year == 0 {
            formatter.dateFormat = "d 'de' MMM"
        } else {
            // Se for um ano diferente, incluir o ano
            formatter.dateFormat = "d 'de' MMM, yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    // Função para extrair até duas linhas de preview, ignorando a primeira linha e linhas só com hora (ex.: 14:32)
    private func getContentPreview(_ content: String) -> String {
        let timeRegex = #"^\d{1,2}:\d{2}$"#

        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Remove título e filtra vazios / horas
        let bodyLines = lines.dropFirst().filter { line in
            guard !line.isEmpty else { return false }
            return line.range(of: timeRegex, options: .regularExpression) == nil
        }

        // Pega até as duas primeiras linhas
        let previewLines = bodyLines.prefix(2)
        return previewLines.joined(separator: "\n")
    }
    
    // Função para remover prefixos [TRASH] e [ARCHIVED] dos títulos
    private func formatTitle(_ title: String) -> String {
        var result = title
        if result.hasPrefix("[TRASH] ") {
            result = String(result.dropFirst(8))
        }
        if result.hasPrefix("[ARCHIVED] ") {
            result = String(result.dropFirst(11))
        }
        return result
    }
    
#if os(macOS)
private func handleSelection(for note: NoteEntity) {
    if NSEvent.modifierFlags.contains(.command) {
        // Multi‑seleção com Command
        if store.selectedNotes.contains(note) {
            store.selectedNotes.remove(note)
            if store.selectedNote?.id == note.id {
                store.selectedNote = store.selectedNotes.first
            }
        } else {
            store.selectedNotes.insert(note)
            store.selectedNote = note
        }
    } else if NSEvent.modifierFlags.contains(.shift) {
        // Seleção de intervalo com Shift
        if let current = store.selectedNote,
           current.id != note.id,
           let s = pinned.firstIndex(where: { $0.id == current.id }),
           let e = pinned.firstIndex(where: { $0.id == note.id }) {
            let r = s <= e ? s...e : e...s
            store.selectedNotes = Set(pinned[r])
        } else {
            store.selectedNotes = [note]
            store.selectedNote  = note
        }
    } else {
        // Seleção única + biometria
        if note.isLocked {
            BiometricAuth.authenticate(
                reason: "Desbloquear nota: \(formatTitle(note.title ?? ""))"
            ) { success in
                if success {
                    note.isLocked = false
                    try? store.context.save()
                }
                DispatchQueue.main.async {
                    store.selectedNotes = [note]
                    store.selectedNote  = note
                }
            }
        } else {
            store.selectedNotes = [note]
            store.selectedNote  = note
        }
    }
}
#else
/// iOS – seleção simples; notas bloqueadas ficam somente leitura.
private func handleSelection(for note: NoteEntity) {
    guard !note.isLocked else { return }
    store.selectedNotes = [note]
    store.selectedNote  = note
}
#endif
}
