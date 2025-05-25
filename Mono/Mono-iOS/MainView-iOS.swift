//
//  MainView-iOS.swift
//  Mono
//
//  Created by Eduardo Freire on 06/05/25.
//

import SwiftUI

/// Layout principal exclusivo para iPhone/iPad.
/// Usa NavigationSplitView nos dispositivos com largura regular
/// (iPad Landscape, por exemplo) e NavigationStack no iPhone.
struct MainView_iOS: View {
    @EnvironmentObject private var store: NotesStore
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var folderSelection: FolderEntity?
    @State private var noteSelection: NoteEntity?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        if sizeClass == .compact {
            // MARK: — iPhone
            NavigationStack {
                SidebarView_iOS(selection: $folderSelection)
                    .navigationDestination(for: FolderEntity.self) { folder in
                        NotesListView(searchText: "")
                            .environmentObject(store)
                            .navigationTitle(folder.name ?? "Notas")
                            
                            
                    }
            }
        } else {
            // MARK: — iPad (regular) e Mac Catalyst
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView_iOS(selection: $folderSelection)
            } content: {
                NotesListView(searchText: "")
                    .environmentObject(store)
                    .navigationTitle(folderSelection?.name ?? "Notas")
            } detail: {
                if let note = noteSelection {
                    EditorView(note: .constant(note))
                        .environmentObject(store)
                } else {
                    ContentUnavailableView("Nenhuma nota selecionada",
                                           systemImage: "note.text")
                }
            }
            .onChange(of: store.selectedNote) { _, newValue in
                noteSelection = newValue
            }
        }
    }
}
