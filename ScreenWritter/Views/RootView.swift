import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @Bindable var store: SessionStore
    @State private var isImportingFiles = false
    @State private var isAddingWebURL = false

    var body: some View {
        NavigationSplitView {
            SessionSidebarView(store: store)
                .navigationTitle("ScreenWritter")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            isAddingWebURL = true
                        } label: {
                            Label("Web", systemImage: "globe")
                        }

                        Button {
                            isImportingFiles = true
                        } label: {
                            Label("Importar", systemImage: "square.and.arrow.down")
                        }
                    }
                }
        } detail: {
            if let session = store.selectedSession {
                AnnotationWorkspaceView(session: session, store: store)
                    .id(session.id)
            } else {
                ContentUnavailableView(
                    "Sin sesiones",
                    systemImage: "pencil.and.outline",
                    description: Text("Importa una web, PDF o imagen para empezar a anotar.")
                )
            }
        }
        .fileImporter(
            isPresented: $isImportingFiles,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                store.importFiles(urls)
            case .failure(let error):
                store.importErrorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $isAddingWebURL) {
            WebURLSheet { text in
                store.addWebSession(from: text)
            }
        }
        .alert("No se pudo importar", isPresented: Binding(
            get: { store.importErrorMessage != nil },
            set: { if !$0 { store.importErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.importErrorMessage ?? "")
        }
    }
}

private struct WebURLSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlText = "https://"
    let onSubmit: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("URL", text: $urlText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
            }
            .navigationTitle("Abrir web")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Abrir") {
                        onSubmit(urlText)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    RootView(store: SessionStore())
}
