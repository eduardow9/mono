// RichTextView_iOS.swift
import SwiftUI
import UIKit

struct RichTextView_iOS: UIViewRepresentable {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = true
        tv.isSelectable = true
        tv.allowsEditingTextAttributes = true          // aceita rich‑text
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.delegate = context.coordinator
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // evita loop de atualização
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextView_iOS
        init(_ parent: RichTextView_iOS) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.attributedText = textView.attributedText
        }
    }
}
