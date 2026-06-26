import Foundation
import PencilKit
import PDFKit
import UIKit
import WebKit

enum AnnotationExporter {
    static func exportImage(session: AnnotationSession, drawing: PKDrawing, contentImage: UIImage?, canvasBounds: CGRect) throws -> URL {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(bounds: canvasBounds, format: format)
        let image = renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(canvasBounds)
            contentImage?.draw(in: canvasBounds)
            drawing.image(from: canvasBounds, scale: format.scale).draw(in: canvasBounds)
        }

        guard let data = image.pngData() else {
            throw ExportError.cannotEncodePNG
        }

        let url = AppLocations.documentsDirectory.appendingPathComponent("\(session.title)-annotated.png")
        try data.write(to: url, options: [.atomic])
        return url
    }

    static func exportPDF(session: AnnotationSession, pdfPageDrawingData: [Int: Data]) throws -> URL {
        guard case .pdf(let sourceURL) = session.contentSource, let document = PDFDocument(url: sourceURL) else {
            throw ExportError.unsupportedContent
        }

        let outputURL = AppLocations.documentsDirectory.appendingPathComponent("\(session.title)-annotated.pdf")
        let output = PDFDocument()

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            let pageBounds = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageBounds.size)
            let pageImage = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: pageBounds.size))
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: pageBounds.height)
                context.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()

                if let drawing = drawing(for: pageIndex, session: session, pdfPageDrawingData: pdfPageDrawingData) {
                    drawing.image(from: pageBounds, scale: UIScreen.main.scale)
                        .draw(in: CGRect(origin: .zero, size: pageBounds.size))
                }
            }

            if let newPage = PDFPage(image: pageImage) {
                output.insert(newPage, at: output.pageCount)
            }
        }

        output.write(to: outputURL)
        return outputURL
    }

    private static func drawing(for pageIndex: Int, session: AnnotationSession, pdfPageDrawingData: [Int: Data]) -> PKDrawing? {
        let data = pdfPageDrawingData[pageIndex] ?? legacyDrawingData(for: pageIndex, session: session)
        guard !data.isEmpty else { return nil }
        return try? PKDrawing(data: data)
    }

    private static func legacyDrawingData(for pageIndex: Int, session: AnnotationSession) -> Data {
        pageIndex == 0 ? session.drawingData : Data()
    }

    enum ExportError: LocalizedError {
        case cannotEncodePNG
        case unsupportedContent

        var errorDescription: String? {
            switch self {
            case .cannotEncodePNG:
                "No se pudo crear el PNG exportado."
            case .unsupportedContent:
                "Este tipo de contenido no admite exportacion PDF."
            }
        }
    }
}
