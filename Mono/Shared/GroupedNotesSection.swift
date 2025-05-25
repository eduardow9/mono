import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Shape with rounded bottom corners only
struct BottomRoundedCorners: Shape {
    var radius: CGFloat = 12
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // right side
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        // bottom
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        // left side
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct GroupedNotesSection: View {
    let group: DateGroup
    let notes: [NoteEntity]
    @EnvironmentObject var store: NotesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader
            notesList
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sectionHeader: some View {
        Text(group.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal, 20)
    }

    private var notesList: some View {
        LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(validNotes, id: \.objectID) { note in
#if os(iOS)
                NavigationLink(value: note) {
                    NoteCard(note: note)
                }
                .buttonStyle(.plain)            // evita o chevron padrão
#else
                NoteCard(note: note)
#endif
            }
        }
        .animation(.easeInOut(duration: 0.35), value: notes)
        .padding(.horizontal, 10)
    }

    private var validNotes: [NoteEntity] {
        notes.filter { $0.id != nil }
    }

    private func NoteCard(note: NoteEntity) -> some View {
        let isSelected = store.selectedNotes.contains(note) || store.selectedNote?.id == note.id
        
        return ZStack(alignment: .bottom) {
            // Background com cantos arredondados
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color("EditorBackground") : Color.sidebar)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .overlay(
                    // Adiciona uma borda mais escura quando selecionado
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color("TextSecondary").opacity(0.2) : Color.clear, lineWidth: 1)
                )
                // Barra inferior: top reto, cantos inferiores arredondados
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(Color("AccentColor"))
                            .frame(height: 4)
                            .padding(.horizontal, 1)                    // recua 1 pt dos lados
                            .mask(BottomRoundedCorners(radius: 12))     // recorta só cantos de baixo
                    }
                }
            // Conteúdo da nota
            ZStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {  // Reduzido de 2 para 4
                        let displayTitle = formatTitle(note.title ?? "Untitled")
                        
                        HStack {
                            Text(displayTitle.isEmpty ? "Sem título" : displayTitle)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("TextPrimary"))
                                .lineLimit(1)
                            
                            
                            if note.isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("TextSecondary"))
                            }
                        }
                        
                        let content = note.content ?? ""
                        let contentText = note.isLocked ? "Nota bloqueada" : getContentPreview(content)
                        
                        Text(contentText.isEmpty ? " " : contentText) // Espaço vazio para manter altura
                            .font(.system(size: 12))
                            .foregroundColor(Color("TextSecondary"))
                            .lineLimit(2)
                            .lineSpacing(1) // Adiciona espaçamento entre linhas
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true) // Permite que o texto use altura natural
                    }
                    .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .top)  // Alinha o conteúdo no topo
                
           
                .padding(.top, 18)      // Padding superior
                .padding(.bottom, 14)  // Padding inferior
                .padding(.leading, 8) // Padding esquerdo
                .padding(.trailing, 8) // Padding direito

                
                // ⏱️ Hora no canto inferior direito
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(formattedLastModified(date: note.dateModified))
                            .font(.system(size: 10))
                            .foregroundColor(Color("TextSecondary"))
#if os(iOS)
                            .padding(.trailing, 18)
#endif
                        
                    }
                    .padding(.bottom, 6)
                    .padding(.horizontal, 6)
                }
            }
            .padding(.horizontal, 6)
        }
        .environmentObject(store)
        .padding(.vertical, 4)
        .frame(height: 110)
#if os(iOS)
        .overlay(alignment: .trailing) {
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("TextSecondary"))
                .padding(.trailing, 6)
        }
#endif
        .onTapGesture {
            handleSelection(for: note)
        }
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
    
    // Função para extrair até duas linhas de preview, ignorando a primeira linha e linhas só com hora
    func getContentPreview(_ content: String) -> String {
        let timeRegex = #"^\d{1,2}:\d{2}$"#

        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Remove título e filtra vazios / horas
        let bodyLines = lines.dropFirst().filter { line in
            guard !line.isEmpty else { return false }
            return line.range(of: timeRegex, options: .regularExpression) == nil
        }

        // Se não houver quebras de linha (conteúdo em uma única linha)
        if lines.count == 1 && !lines[0].isEmpty {
            let firstLine = lines[0]
            // Retornar vazio se for muito curto (provavelmente é só o título)
            if firstLine.count <= 30 {
                return ""
            }
            // Retornar o conteúdo após os primeiros ~30 caracteres (assumindo que é o título)
            let index = firstLine.index(firstLine.startIndex, offsetBy: min(30, firstLine.count))
            return String(firstLine[index...]).trimmingCharacters(in: .whitespaces)
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
            if let currentNote = store.selectedNote,
               currentNote.id != note.id,
               let start = validNotes.firstIndex(where: { $0.id == currentNote.id }),
               let end   = validNotes.firstIndex(where: { $0.id == note.id }) {
                let range = start <= end ? start...end : end...start
                store.selectedNotes = Set(validNotes[range])
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
                        DispatchQueue.main.async {
                            store.selectedNotes = [note]
                            store.selectedNote  = note
                        }
                    }
                }
            } else {
                store.selectedNotes = [note]
                store.selectedNote  = note
            }
        }
    }
#else
    /// iOS – seleção simples, sem modificadores de tecla
    private func handleSelection(for note: NoteEntity) {
        if note.isLocked { return }            // nota bloqueada mostra visualização read‑only
        store.selectedNotes = [note]
        store.selectedNote  = note
    }
#endif
}

#Preview {
    ContentView()
        .environmentObject(NotesStore(context: PersistenceController.shared.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .frame(width: 1200, height: 700)
}
