import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        Task {
            await importSharedItems()
        }
    }

    private func configureView() {
        view.backgroundColor = .systemBackground

        statusLabel.text = "Importando en ScreenWritter..."
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func importSharedItems() async {
        do {
            try prepareInbox()
            let attachments = extensionContext?.inputItems
                .compactMap { $0 as? NSExtensionItem }
                .flatMap { $0.attachments ?? [] } ?? []

            var importedCount = 0
            for provider in attachments {
                if try await importWebURL(from: provider) {
                    importedCount += 1
                    continue
                }

                if try await importFile(from: provider) {
                    importedCount += 1
                    continue
                }

                if try await importImage(from: provider) {
                    importedCount += 1
                }
            }

            statusLabel.text = importedCount > 0
                ? "Importado. Abre ScreenWritter para anotar."
                : "No se encontro contenido compatible."

            try await Task.sleep(nanoseconds: 800_000_000)
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            statusLabel.text = error.localizedDescription
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            extensionContext?.cancelRequest(withError: error)
        }
    }

    private func importWebURL(from provider: NSItemProvider) async throws -> Bool {
        guard provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else { return false }
        let item = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier)

        if let url = item as? URL {
            try url.absoluteString.write(to: inboxURL(for: "shared-\(UUID().uuidString).url"), atomically: true, encoding: .utf8)
            return true
        }

        return false
    }

    private func importFile(from provider: NSItemProvider) async throws -> Bool {
        let supportedTypes = [UTType.pdf.identifier, UTType.image.identifier, UTType.fileURL.identifier]
        guard let typeIdentifier = supportedTypes.first(where: provider.hasItemConformingToTypeIdentifier) else {
            return false
        }

        let item = try await provider.loadItem(forTypeIdentifier: typeIdentifier)
        guard let sourceURL = item as? URL else { return false }

        let scoped = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if scoped {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let destination = try inboxURL(for: "\(UUID().uuidString)-\(sourceURL.lastPathComponent)")
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return true
    }

    private func importImage(from provider: NSItemProvider) async throws -> Bool {
        guard provider.canLoadObject(ofClass: UIImage.self) else { return false }
        let image = try await provider.loadImage()
        guard let data = image.pngData() else { return false }
        try data.write(to: inboxURL(for: "shared-\(UUID().uuidString).png"), options: [.atomic])
        return true
    }

    private func prepareInbox() throws {
        guard let inbox = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.screenwritter.shared")?
            .appendingPathComponent("Inbox", isDirectory: true)
        else {
            throw ShareImportError.missingAppGroup
        }

        try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
    }

    private func inboxURL(for fileName: String) throws -> URL {
        guard let inbox = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.screenwritter.shared")?
            .appendingPathComponent("Inbox", isDirectory: true)
        else {
            throw ShareImportError.missingAppGroup
        }

        return inbox.appendingPathComponent(fileName)
    }

    enum ShareImportError: LocalizedError {
        case missingAppGroup

        var errorDescription: String? {
            "No se pudo acceder al App Group compartido."
        }
    }
}

private extension NSItemProvider {
    func loadItem(forTypeIdentifier typeIdentifier: String) async throws -> NSSecureCoding? {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: item)
                }
            }
        }
    }

    func loadImage() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            loadObject(ofClass: UIImage.self) { object, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let image = object as? UIImage else {
                    continuation.resume(throwing: CocoaError(.fileReadCorruptFile))
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }
}
