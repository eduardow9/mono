//  SearchBarView_iOS.swift
//  Mono (iOS target)
//  Use “Target Membership” → marque APENAS Mono‑iOS.

import SwiftUI

/// Barra de busca simplificada para iPhone/iPad.
/// Mantém a mesma assinatura básica do componente macOS:
///     SearchBarView(text: $searchText) { onCommit() }
struct SearchBarView_iOS: View {
    @Binding var text: String
    var placeholder: String = "Buscar"
    var onCommit: () -> Void = {}

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            // Campo de texto
            TextField(placeholder, text: $text, onCommit: onCommit)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($isFocused)

            // Botão limpar
            if !text.isEmpty {
                Button {
                    text = ""
                    onCommit()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .onAppear { isFocused = true }
    }
}
