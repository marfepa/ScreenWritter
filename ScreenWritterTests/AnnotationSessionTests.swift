import PencilKit
import XCTest
@testable import ScreenWritter

final class AnnotationSessionTests: XCTestCase {
    func testSessionCodableRoundTripPreservesContentAndDrawingData() throws {
        let source = ContentSource.web(try XCTUnwrap(URL(string: "https://developer.apple.com")))
        let drawingData = Data([1, 2, 3])
        let session = AnnotationSession(
            id: UUID(uuidString: "E524E944-B68D-4AA7-BE7E-1AB614F67E39")!,
            title: "Demo",
            contentSource: source,
            drawingData: drawingData,
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 20)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(AnnotationSession.self, from: encoder.encode(session))

        XCTAssertEqual(decoded, session)
        XCTAssertEqual(decoded.contentKind, .web)
    }

    func testPencilKitEmptyDrawingDataCanBeRestored() throws {
        let drawing = PKDrawing()
        let restored = try PKDrawing(data: drawing.dataRepresentation())

        XCTAssertEqual(restored.dataRepresentation(), drawing.dataRepresentation())
    }

    func testImportCoordinatorNormalizesWebURLs() throws {
        let source = try XCTUnwrap(ImportCoordinator.makeWebSource(from: "developer.apple.com"))

        XCTAssertEqual(source, .web(try XCTUnwrap(URL(string: "https://developer.apple.com"))))
    }
}
