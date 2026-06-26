import Foundation

struct AnnotationSession: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var contentSource: ContentSource
    var drawingData: Data
    var pdfPageDrawingData: [Int: Data]
    var createdAt: Date
    var updatedAt: Date
    var thumbnailFileName: String?

    var contentKind: ContentSource.ContentKind {
        contentSource.kind
    }

    init(
        id: UUID = UUID(),
        title: String? = nil,
        contentSource: ContentSource,
        drawingData: Data = Data(),
        pdfPageDrawingData: [Int: Data] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        thumbnailFileName: String? = nil
    ) {
        self.id = id
        self.title = title ?? contentSource.title
        self.contentSource = contentSource
        self.drawingData = drawingData
        self.pdfPageDrawingData = pdfPageDrawingData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailFileName = thumbnailFileName
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case contentSource
        case drawingData
        case pdfPageDrawingData
        case createdAt
        case updatedAt
        case thumbnailFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        contentSource = try container.decode(ContentSource.self, forKey: .contentSource)
        drawingData = try container.decode(Data.self, forKey: .drawingData)
        pdfPageDrawingData = try container.decodeIfPresent([Int: Data].self, forKey: .pdfPageDrawingData) ?? [:]
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        thumbnailFileName = try container.decodeIfPresent(String.self, forKey: .thumbnailFileName)
    }
}
