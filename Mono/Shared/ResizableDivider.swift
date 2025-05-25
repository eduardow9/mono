import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Divider redimensionável entre a sidebar e a lista.
/// Usa uma linha visível de 1 pt e uma área “hit” maior para facilitar o arrasto.
struct ResizableDivider: View {
    @Binding var width: CGFloat
    
    // Limites para a largura ajustável
    private let minWidth: CGFloat = 180
    private let maxWidth: CGFloat = 500
    
    // Largura da área interativa (invisível)
    private let hitAreaWidth: CGFloat = 12
    
    var body: some View {
        Rectangle()                                   // área de hit transparente
            .fill(Color.clear)
            .frame(width: hitAreaWidth)
            .contentShape(Rectangle())
            .overlay(EmptyView())
            #if os(macOS)
            // Cursor ⟷ ao passar o mouse
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            #endif
            // Arrasto horizontal
            .ignoresSafeArea(edges: .vertical)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newWidth = width + value.translation.width
                        width = max(minWidth, min(maxWidth, newWidth))
                    }
            )
    }
}
