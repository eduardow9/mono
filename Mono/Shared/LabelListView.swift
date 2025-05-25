import SwiftUI

struct LabelListView: View {
    @EnvironmentObject var store: NotesStore
    @Binding var selectedLabelID: UUID?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !store.tags.isEmpty {
                Text("Etiquetas")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.leading, 2)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.monoTextSecondary)
      
                ForEach(store.tags) { (label: NotesStore.LabelTag) in
                    ZStack(alignment: .leading) {
                        if selectedLabelID == label.id {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.monoRectangleSelection)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 2)
                                .frame(height: 28)
                        }

                        HStack(spacing: 6) {
                            Circle()
                                .fill(label.color)
                                .frame(width: 8, height: 8)
                                .frame(minWidth: 22, alignment: .trailing)

                            Text(label.name)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color.monoTextPrimary)
                        }
                        .padding(.vertical, 2)
                        .padding(.leading, 2)
                        .frame(height: 28)
                        .contentShape(Rectangle())
                        .onTapGesture {               // não use $
                            selectedLabelID = label.id
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct LabelTag: Identifiable, Hashable {
    let id = UUID()
    var name: String
    /// Tint shown in the label list; defaults to accentColor
    var color: Color = .accentColor
}
