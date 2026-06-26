import PencilKit
import PDFKit
import UIKit
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

    func testLegacySessionWithoutPDFPageDrawingDataDecodesWithEmptyPageDrawings() throws {
        let legacySession = LegacyAnnotationSession(
            id: UUID(uuidString: "E524E944-B68D-4AA7-BE7E-1AB614F67E39")!,
            title: "Legacy",
            contentSource: .pdf(URL(fileURLWithPath: "/tmp/demo.pdf")),
            drawingData: Data([1, 2, 3]),
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 20),
            thumbnailFileName: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(AnnotationSession.self, from: encoder.encode(legacySession))

        XCTAssertEqual(decoded.drawingData, legacySession.drawingData)
        XCTAssertEqual(decoded.pdfPageDrawingData, [:])
    }

    func testSessionCodableRoundTripPreservesPDFPageDrawingData() throws {
        let session = AnnotationSession(
            title: "PDF",
            contentSource: .pdf(URL(fileURLWithPath: "/tmp/demo.pdf")),
            drawingData: Data([1]),
            pdfPageDrawingData: [
                0: Data([2, 3]),
                2: Data([4, 5])
            ],
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 20)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(AnnotationSession.self, from: encoder.encode(session))

        XCTAssertEqual(decoded, session)
        XCTAssertEqual(decoded.pdfPageDrawingData[0], Data([2, 3]))
        XCTAssertEqual(decoded.pdfPageDrawingData[2], Data([4, 5]))
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

    func testExportPDFPreservesMultiplePages() throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        makePDF(at: sourceURL, pageCount: 2)

        let session = AnnotationSession(
            title: "Multipage",
            contentSource: .pdf(sourceURL),
            pdfPageDrawingData: [
                1: PKDrawing().dataRepresentation()
            ]
        )

        let outputURL = try AnnotationExporter.exportPDF(
            session: session,
            pdfPageDrawingData: session.pdfPageDrawingData
        )
        let outputDocument = try XCTUnwrap(PDFDocument(url: outputURL))

        XCTAssertEqual(outputDocument.pageCount, 2)
    }

    func testExportPDFAcceptsLegacyFirstPageDrawingData() throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        makePDF(at: sourceURL, pageCount: 2)

        let session = AnnotationSession(
            title: "LegacyMultipage",
            contentSource: .pdf(sourceURL),
            drawingData: PKDrawing().dataRepresentation()
        )

        let outputURL = try AnnotationExporter.exportPDF(session: session, pdfPageDrawingData: [:])
        let outputDocument = try XCTUnwrap(PDFDocument(url: outputURL))

        XCTAssertEqual(outputDocument.pageCount, 2)
    }

    private func makePDF(at url: URL, pageCount: Int) {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
        try? renderer.writePDF(to: url) { context in
            for index in 0..<pageCount {
                context.beginPage()
                "\(index)".draw(at: CGPoint(x: 20, y: 20), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 24),
                    .foregroundColor: UIColor.black
                ])
            }
        }
    }
}

private struct LegacyAnnotationSession: Codable {
    var id: UUID
    var title: String
    var contentSource: ContentSource
    var drawingData: Data
    var createdAt: Date
    var updatedAt: Date
    var thumbnailFileName: String?
}
