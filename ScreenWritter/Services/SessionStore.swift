import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    private(set) var sessions: [AnnotationSession] = []
    var selectedSessionID: AnnotationSession.ID?
    var importErrorMessage: String?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var selectedSession: AnnotationSession? {
        guard let selectedSessionID else { return sessions.first }
        return sessions.first { $0.id == selectedSessionID }
    }

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() async {
        do {
            try AppLocations.prepareLocalDirectories()
            let files = try FileManager.default.contentsOfDirectory(
                at: AppLocations.sessionsDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            sessions = try files
                .filter { $0.pathExtension == "json" }
                .map { try decoder.decode(AnnotationSession.self, from: Data(contentsOf: $0)) }
                .sorted { $0.updatedAt > $1.updatedAt }

            selectedSessionID = sessions.first?.id
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    func createSession(from source: ContentSource) {
        var session = AnnotationSession(contentSource: source)
        session.updatedAt = Date()
        sessions.insert(session, at: 0)
        selectedSessionID = session.id
        save(session)
    }

    func open(_ url: URL) async {
        if url.isFileURL {
            do {
                createSession(from: try ImportCoordinator.importFile(at: url))
            } catch {
                importErrorMessage = error.localizedDescription
            }
        } else {
            createSession(from: .web(url))
        }
    }

    func addWebSession(from text: String) {
        guard let source = ImportCoordinator.makeWebSource(from: text) else {
            importErrorMessage = "No se pudo crear una URL valida."
            return
        }
        createSession(from: source)
    }

    func importFiles(_ urls: [URL]) {
        for url in urls {
            do {
                createSession(from: try ImportCoordinator.importFile(at: url))
            } catch {
                importErrorMessage = error.localizedDescription
            }
        }
    }

    func importSharedItems() async {
        do {
            let importedSources = try ImportCoordinator.importSharedInbox()
            importedSources.forEach(createSession)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    func updateDrawing(for id: AnnotationSession.ID, drawingData: Data) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].drawingData = drawingData
        save(sessions[index])
    }

    func updatePDFPageDrawing(for id: AnnotationSession.ID, pageIndex: Int, drawingData: Data) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].pdfPageDrawingData[pageIndex] = drawingData
        save(sessions[index])
    }

    func clearDrawings(for id: AnnotationSession.ID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].drawingData = Data()
        sessions[index].pdfPageDrawingData = [:]
        sessions[index].updatedAt = Date()
        save(sessions[index])
    }

    func rename(_ id: AnnotationSession.ID, title: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].title = title
        sessions[index].updatedAt = Date()
        save(sessions[index])
    }

    func delete(_ session: AnnotationSession) {
        sessions.removeAll { $0.id == session.id }
        try? FileManager.default.removeItem(at: sessionFileURL(for: session.id))
        selectedSessionID = sessions.first?.id
    }

    func save(_ session: AnnotationSession) {
        do {
            try AppLocations.prepareLocalDirectories()
            let data = try encoder.encode(session)
            try data.write(to: sessionFileURL(for: session.id), options: [.atomic])
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func sessionFileURL(for id: AnnotationSession.ID) -> URL {
        AppLocations.sessionsDirectory.appendingPathComponent("\(id.uuidString).json")
    }
}
