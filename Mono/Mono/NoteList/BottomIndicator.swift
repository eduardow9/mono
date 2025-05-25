import SwiftUI

// Correção da barra indicadora para ficar corretamente no fundo do card
struct BottomIndicator: Shape {
    func path(in rect: CGRect) -> Path {
        // Criar um simples retângulo sem cantos arredondados
        // para ficar exatamente como na primeira imagem
        var path = Path()
        
        // Começa no canto superior esquerdo
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Vai para o canto superior direito
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        
        // Vai para o canto inferior direito
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        
        // Vai para o canto inferior esquerdo
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        
        // Fecha o caminho
        path.closeSubpath()
        
        return path
    }
}
