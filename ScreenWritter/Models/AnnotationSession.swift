import Foundation

struct AnnotationSession: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var contentSource: ContentSource
    var drawingData: Data
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
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        thumbnailFileName: String? = nil
    ) {
        self.id = id
        self.title = title ?? contentSource.title
        self.contentSource = contentSource
        self.drawingData = drawingData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailFileName = thumbnailFileName
    }
}
