import Foundation
import UniformTypeIdentifiers

enum ContentSource: Codable, Equatable, Identifiable, Sendable {
    case web(URL)
    case pdf(URL)
    case image(URL)

    var id: String {
        switch self {
        case .web(let url):
            "web:\(url.absoluteString)"
        case .pdf(let url):
            "pdf:\(url.absoluteString)"
        case .image(let url):
            "image:\(url.absoluteString)"
        }
    }

    var title: String {
        switch self {
        case .web(let url):
            url.host ?? url.absoluteString
        case .pdf(let url), .image(let url):
            url.deletingPathExtension().lastPathComponent
        }
    }

    var kind: ContentKind {
        switch self {
        case .web:
            .web
        case .pdf:
            .pdf
        case .image:
            .image
        }
    }

    var url: URL {
        switch self {
        case .web(let url), .pdf(let url), .image(let url):
            url
        }
    }

    enum ContentKind: String, Codable, CaseIterable, Identifiable, Sendable {
        case web
        case pdf
        case image

        var id: String { rawValue }

        var title: String {
            switch self {
            case .web:
                "Web"
            case .pdf:
                "PDF"
            case .image:
                "Imagen"
            }
        }
    }
}
