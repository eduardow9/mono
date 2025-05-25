import SwiftUI
import AppKit
import LocalAuthentication

struct LockedNoteView: View {
    let note: NoteEntity
    @EnvironmentObject var store: NotesStore
    @Binding var isUnlocked: Bool

    // Armazena a mensagem apropriada de acordo com o tipo de biometria
    private let biometricPrompt: String

    init(note: NoteEntity, isUnlocked: Binding<Bool>) {
        self.note = note
        self._isUnlocked = isUnlocked

        let context = LAContext()
        var tempPrompt = "Use a autenticação do seu dispositivo para desbloquear."

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            switch context.biometryType {
            case .faceID:
                tempPrompt = "Use o Face ID para desbloquear sua nota."
            case .touchID:
                tempPrompt = "Use o Touch ID para desbloquear sua nota."
            default:
                break
            }
        }

        self.biometricPrompt = tempPrompt
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Você bloqueou esta nota.")
                .font(.title2)
                .foregroundColor(.secondary)

            Text(biometricPrompt)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding(.horizontal)

            Image(systemName: "touchid")
                .font(.system(size: 64))
                .foregroundColor(Color.monoAccent)
                .padding()
                .onTapGesture {
                    authenticateAndUnlock()
                }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)  // Fundo branco para a tela de bloqueio
        .cornerRadius(12)         // Cantos arredondados consistentes
    }

    private func authenticateAndUnlock() {
        BiometricAuth.authenticate(reason: "Desbloquear nota: \(note.title ?? "")") { success in
            if success {
                isUnlocked = true
            }
        }
    }
}

