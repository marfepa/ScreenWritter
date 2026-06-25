import Foundation
import UniformTypeIdentifiers

enum ImportCoordinator {
    static func makeWebSource(from text: String) -> ContentSource? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil {
            return .web(url)
        }

        if let url = URL(string: "https://\(trimmed)") {
            return .web(url)
        }

        return nil
    }

    static func importFile(at sourceURL: URL) throws -> ContentSource {
        try AppLocations.prepareLocalDirectories()

        let source = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if source {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let type = try sourceURL.resourceValues(forKeys: [.contentTypeKey]).contentType
        let extensionFallback = sourceURL.pathExtension.lowercased()
        let kind = kindForContent(type: type, extensionFallback: extensionFallback)

        let fileName = "\(UUID().uuidString)-\(sourceURL.lastPathComponent)"
        let destinationURL = AppLocations.importsDirectory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        switch kind {
        case .pdf:
            return .pdf(destinationURL)
        case .image:
            return .image(destinationURL)
        case .web:
            return .web(destinationURL)
        }
    }

    static func importSharedInbox() throws -> [ContentSource] {
        guard let inbox = AppLocations.sharedInboxDirectory else { return [] }
        try AppLocations.prepareLocalDirectories()

        guard FileManager.default.fileExists(atPath: inbox.path) else { return [] }
        let files = try FileManager.default.contentsOfDirectory(
            at: inbox,
            includingPropertiesForKeys: [.contentTypeKey],
            options: [.skipsHiddenFiles]
        )

        var sources: [ContentSource] = []
        for file in files {
            if file.pathExtension == "url", let text = try? String(contentsOf: file), let source = makeWebSource(from: text) {
                sources.append(source)
                try? FileManager.default.removeItem(at: file)
                continue
            }

            let destination = AppLocations.importsDirectory.appendingPathComponent(file.lastPathComponent)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: file, to: destination)

            let type = try destination.resourceValues(forKeys: [.contentTypeKey]).contentType
            let kind = kindForContent(type: type, extensionFallback: destination.pathExtension.lowercased())
            switch kind {
            case .pdf:
                sources.append(.pdf(destination))
            case .image:
                sources.append(.image(destination))
            case .web:
                break
            }
        }

        return sources
    }

    private static func kindForContent(type: UTType?, extensionFallback: String) -> ContentSource.ContentKind {
        if type?.conforms(to: .pdf) == true || extensionFallback == "pdf" {
            return .pdf
        }

        if type?.conforms(to: .image) == true || ["png", "jpg", "jpeg", "heic", "gif", "tiff"].contains(extensionFallback) {
            return .image
        }

        return .web
    }
}
