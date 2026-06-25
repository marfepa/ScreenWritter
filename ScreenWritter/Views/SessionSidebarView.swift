import SwiftUI

struct SessionSidebarView: View {
    @Bindable var store: SessionStore

    var body: some View {
        List(selection: $store.selectedSessionID) {
            ForEach(store.sessions) { session in
                VStack(alignment: .leading, spacing: 4) {
                    Label(session.title, systemImage: iconName(for: session.contentKind))
                        .font(.headline)
                        .lineLimit(1)

                    Text(session.updatedAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(session.id)
                .contextMenu {
                    Button(role: .destructive) {
                        store.delete(session)
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
        }
        .overlay {
            if store.sessions.isEmpty {
                ContentUnavailableView(
                    "Nada importado",
                    systemImage: "doc.badge.plus",
                    description: Text("Usa Web o Importar para crear la primera sesion.")
                )
            }
        }
    }

    private func iconName(for kind: ContentSource.ContentKind) -> String {
        switch kind {
        case .web:
            "globe"
        case .pdf:
            "doc.richtext"
        case .image:
            "photo"
        }
    }
}
