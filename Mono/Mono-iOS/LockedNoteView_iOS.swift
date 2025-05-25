//
//  LockedNoteView_iOS.swift
//  Mono   (alvo **somente** Mono‑iOS)
//
//  Exibe nota bloqueada e oferece desbloqueio via Face ID / Touch ID.
//

import SwiftUI
import LocalAuthentication

struct LockedNoteView_iOS: View {
    /// Nota bloqueada – apenas para exibir título / status, sem editar.
    let note: NoteEntity
    /// Bind para avisar o Editor quando a nota foi desbloqueada.
    @Binding var isUnlocked: Bool

    @State private var authError: String?

    var body: some View {
        VStack(spacing: 24) {

            Image(systemName: "lock.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(.secondary)

            Text("Esta nota está bloqueada.")
                .font(.headline)
                .multilineTextAlignment(.center)

            Button("Desbloquear") { authenticate() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            if let error = authError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    // MARK: ‑ Autenticação biométrica

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                        error: &error) else {
            authError = "Biometria não disponível."
            return
        }

        let reason = "Desbloquear nota protegida"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: reason) { success, evaluateError in
            DispatchQueue.main.async {
                if success {
                    isUnlocked = true
                } else {
                    authError = evaluateError?.localizedDescription ?? "Falha na autenticação."
                }
            }
        }
    }
}

#if DEBUG
struct LockedNoteView_iOS_Previews: PreviewProvider {
    static var previews: some View {
        LockedNoteView_iOS(
            note: NoteEntity(),
            isUnlocked: .constant(false)
        )
    }
}
#endif
