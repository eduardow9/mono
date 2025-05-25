import SwiftUI

#if os(macOS)
import AppKit
#endif

struct NoteRow: View {
    @EnvironmentObject var store: NotesStore
    var note: NoteEntity
    var isSelected: Bool

    @Environment(\.colorScheme) private var colorScheme

    // MARK: – Body
    var body: some View {
        #if os(iOS)
        NavigationLink {
            EditorView(note: .constant(note))
                .environmentObject(store)
        } label: {
            rowContent
        }        #else   // macOS mantém o comportamento atual (tap só seleciona)
        rowContent
            .onTapGesture {
                if let tv = textViewGlobal,
                   tv.window?.firstResponder === tv {
                    tv.window?.makeFirstResponder(nil)
                }
                // seleção é tratada no nível superior
            }
        #endif
    }

    /// Conteúdo visual reutilizado entre macOS / iOS
    private var rowContent: some View {
        HStack(spacing: 0) {
            // Conteúdo (título, cadeado e texto)
            VStack(alignment: .leading, spacing: 0) {  // Aumentado de 4 para 6
                HStack {
                    Text(note.title ?? "Nova nota")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.monoTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    if note.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.monoTextSecondary)
                    }
                }

                if let content = note.content,
                   !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(note.isLocked ? "Nota bloqueada" : content)
                        .font(.system(size: 14))
                        .foregroundColor(Color.monoTextSecondary)
                        .lineLimit(2)
                        .frame(height: 44)
                }
            }
            .padding(.vertical, 12)  // Aumentado de 10 para 12
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 70)
        .contentShape(Rectangle())
    }
}
