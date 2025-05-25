import SwiftUI
import UIKit

struct SmartTextView_iOS: UIViewRepresentable {
    @Binding var text: NSAttributedString

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = true
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.delegate = context.coordinator
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != text {
            uiView.attributedText = text
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: SmartTextView_iOS
        init(_ parent: SmartTextView_iOS) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText
        }
    }
}
