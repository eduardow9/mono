import SwiftUI

/// Ponto de entrada da **versão iOS** do Mono.
/// (A versão para macOS continua em `MonoApp.swift`.)
@main
struct Mono_iOSApp: App {
    /// Store único para todo o app
    @StateObject private var store = NotesStore(
        context: PersistenceController.shared.container.viewContext
    )

    var body: some Scene {
        WindowGroup {
            MainView_iOS()                       // ← tela raiz no iPhone
                .environmentObject(store)        // injeta o NotesStore
                .environment(\.managedObjectContext,
                              PersistenceController.shared.container.viewContext)
        }
    }
}
