import SwiftUI

struct MarkdownToolbar: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Button(action: {
                    NotificationCenter.default.post(name: .applyMarkdownBold, object: nil)
                }) {
                    Text("B")
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Negrito (Markdown)")
                
                Button(action: {
                    NotificationCenter.default.post(name: .applyMarkdownItalic, object: nil)
                }) {
                    Text("I")
                        .italic()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Itálico (Markdown)")
                
                Button(action: {
                    NotificationCenter.default.post(name: .applyMarkdownH1, object: nil)
                }) {
                    Text("H1")
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Título 1 (Markdown)")
                
                Button(action: {
                    NotificationCenter.default.post(name: .applyMarkdownH2, object: nil)
                }) {
                    Text("H2")
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Título 2 (Markdown)")
                
                Button(action: {
                    NotificationCenter.default.post(name: .applyMarkdownH3, object: nil)
                }) {
                    Text("H3")
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Título 3 (Markdown)")
                
                Button(action: {
                    NotificationCenter.default.post(name: .applyMarkdownBulletList, object: nil)
                }) {
                    Image(systemName: "list.bullet")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Lista com marcadores (Markdown)")
                
                Button(action: {
                    NotificationCenter.default.post(name: .applyMarkdownNumberedList, object: nil)
                }) {
                    Image(systemName: "list.number")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Lista numerada (Markdown)")
                
                Button(action: {
                    NotificationCenter.default.post(name: .applyMarkdownLink, object: nil)
                }) {
                    Image(systemName: "link")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Link (Markdown)")
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color("FrameColor").opacity(0.5))
        }
    }
}
