import PDFKit
import PencilKit
import SwiftUI
import WebKit

struct ContentRenderer: View {
    let source: ContentSource
    let mode: AnnotationMode
    @Binding var drawing: PKDrawing
    @Binding var pdfPageDrawings: [Int: Data]
    let drawingResetID: UUID
    let legacyPDFDrawingData: Data
    let onDrawingChanged: (PKDrawing) -> Void
    let onPDFPageDrawingChanged: (Int, PKDrawing) -> Void
    let onImageContentBoundsChanged: (CGRect) -> Void

    var body: some View {
        switch source {
        case .web(let url):
            WebContentView(
                url: url,
                mode: mode,
                drawing: $drawing,
                drawingResetID: drawingResetID,
                onDrawingChanged: onDrawingChanged
            )
        case .pdf(let url):
            PDFContentView(
                url: url,
                mode: mode,
                pdfPageDrawings: $pdfPageDrawings,
                drawingResetID: drawingResetID,
                legacyDrawingData: legacyPDFDrawingData,
                onPageDrawingChanged: onPDFPageDrawingChanged
            )
        case .image(let url):
            ImageContentView(
                url: url,
                mode: mode,
                drawing: $drawing,
                drawingResetID: drawingResetID,
                onDrawingChanged: onDrawingChanged,
                onContentBoundsChanged: onImageContentBoundsChanged
            )
        }
    }
}

struct WebContentView: UIViewRepresentable {
    let url: URL
    let mode: AnnotationMode
    @Binding var drawing: PKDrawing
    let drawingResetID: UUID
    let onDrawingChanged: (PKDrawing) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WebAnnotationContainerView {
        let containerView = WebAnnotationContainerView()
        context.coordinator.attach(to: containerView)
        return containerView
    }

    func updateUIView(_ containerView: WebAnnotationContainerView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateMode()
        context.coordinator.updateDrawing(drawing, resetID: drawingResetID)
        context.coordinator.loadURLIfNeeded(url)
        context.coordinator.updateCanvasFrame()
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: WebContentView
        private var toolPicker: PKToolPicker?
        private var contentSizeObservation: NSKeyValueObservation?
        private var contentOffsetObservation: NSKeyValueObservation?
        private weak var containerView: WebAnnotationContainerView?
        private var lastExternalDrawingData: Data?
        private var lastRequestedURL: URL?
        private var lastResetID: UUID?

        init(parent: WebContentView) {
            self.parent = parent
        }

        func attach(to containerView: WebAnnotationContainerView) {
            self.containerView = containerView
            configure(containerView.canvasView)
            containerView.onLayout = { [weak self] in
                self?.updateCanvasFrame()
            }
            let webView = containerView.webView
            contentSizeObservation = webView.scrollView.observe(\.contentSize, options: [.initial, .new]) { [weak self] scrollView, _ in
                DispatchQueue.main.async {
                    self?.updateCanvasFrame(scrollView: scrollView)
                }
            }
            contentOffsetObservation = webView.scrollView.observe(\.contentOffset, options: [.initial, .new]) { [weak self] scrollView, _ in
                DispatchQueue.main.async {
                    self?.updateCanvasFrame(scrollView: scrollView)
                }
            }
        }

        func updateDrawing(_ drawing: PKDrawing, resetID: UUID) {
            guard let canvasView = containerView?.canvasView else { return }
            guard resetID != lastResetID || lastExternalDrawingData == nil else { return }
            let drawingData = drawing.dataRepresentation()
            if resetID != lastResetID {
                canvasView.drawing = drawing
                lastExternalDrawingData = drawingData
                lastResetID = resetID
                return
            }
            guard drawingData != lastExternalDrawingData else { return }
            canvasView.drawing = drawing
            lastExternalDrawingData = drawingData
        }

        func loadURLIfNeeded(_ url: URL) {
            guard lastRequestedURL != url else { return }
            lastRequestedURL = url
            containerView?.webView.load(URLRequest(url: url))
        }

        func updateCanvasFrame() {
            guard let containerView else { return }
            updateCanvasFrame(scrollView: containerView.webView.scrollView)
        }

        func updateCanvasFrame(scrollView: UIScrollView) {
            guard let containerView else { return }
            let size = CGSize(
                width: max(scrollView.contentSize.width, scrollView.bounds.width),
                height: max(scrollView.contentSize.height, scrollView.bounds.height)
            )
            let canvasView = containerView.canvasView
            canvasView.frame = CGRect(origin: .zero, size: size)
                .offsetBy(dx: -scrollView.contentOffset.x, dy: -scrollView.contentOffset.y)
            containerView.bringSubviewToFront(canvasView)
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onDrawingChanged(canvasView.drawing)
        }

        func updateMode() {
            guard let canvasView = containerView?.canvasView else { return }
            configureAnnotationCanvas(canvasView, mode: parent.mode, role: .overlay)
            configureToolPicker(for: canvasView, visible: parent.mode == .annotate)
        }

        private func configure(_ canvasView: PKCanvasView) {
            canvasView.delegate = self
            canvasView.isOpaque = false
            canvasView.backgroundColor = .clear
            canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 6)
            canvasView.isScrollEnabled = false
            canvasView.alwaysBounceVertical = false
            canvasView.alwaysBounceHorizontal = false
            configureAnnotationCanvas(canvasView, mode: parent.mode, role: .overlay)
            configureToolPicker(for: canvasView, visible: parent.mode == .annotate)
        }

        private func configureToolPicker(for canvasView: PKCanvasView, visible: Bool) {
            if toolPicker == nil {
                let picker = PKToolPicker()
                picker.addObserver(canvasView)
                toolPicker = picker
            }
            if visible {
                canvasView.becomeFirstResponder()
            } else {
                canvasView.resignFirstResponder()
            }
            toolPicker?.setVisible(visible, forFirstResponder: canvasView)
        }
    }
}

final class WebAnnotationContainerView: UIView {
    let webView: WKWebView
    let canvasView = PKCanvasView()
    var onLayout: (() -> Void)?

    override init(frame: CGRect) {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(frame: frame)
        backgroundColor = .systemBackground
        clipsToBounds = true
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        addSubview(webView)
        addSubview(canvasView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = bounds
        onLayout?()
    }
}

struct PDFContentView: UIViewRepresentable {
    let url: URL
    let mode: AnnotationMode
    @Binding var pdfPageDrawings: [Int: Data]
    let drawingResetID: UUID
    let legacyDrawingData: Data
    let onPageDrawingChanged: (Int, PKDrawing) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        pdfView.pageOverlayViewProvider = context.coordinator
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        context.coordinator.parent = self
        pdfView.pageOverlayViewProvider = context.coordinator
        if pdfView.document?.documentURL != url {
            pdfView.document = PDFDocument(url: url)
        }
        context.coordinator.updateMode()
        context.coordinator.resetVisibleCanvasesIfNeeded(resetID: drawingResetID, pdfView: pdfView)
    }

    final class Coordinator: NSObject, PDFPageOverlayViewProvider, PKCanvasViewDelegate {
        var parent: PDFContentView
        private var toolPickers: [ObjectIdentifier: PKToolPicker] = [:]
        private var pageIndexes: [ObjectIdentifier: Int] = [:]
        private var pageDrawingData: [Int: Data] = [:]
        private var visibleCanvases: [ObjectIdentifier: WeakCanvasReference] = [:]
        private var lastResetID: UUID?

        init(parent: PDFContentView) {
            self.parent = parent
        }

        func pdfView(_ pdfView: PDFView, overlayViewFor page: PDFPage) -> UIView? {
            let canvasView = PKCanvasView()
            let pageIndex = pdfView.document?.index(for: page) ?? 0
            pageIndexes[ObjectIdentifier(canvasView)] = pageIndex
            visibleCanvases[ObjectIdentifier(canvasView)] = WeakCanvasReference(canvasView)
            configure(canvasView)
            canvasView.drawing = drawing(for: pageIndex)
            return canvasView
        }

        func pdfView(_ pdfView: PDFView, willDisplayOverlayView overlayView: UIView, for page: PDFPage) {
            guard let canvasView = overlayView as? PKCanvasView else { return }
            let pageIndex = pdfView.document?.index(for: page) ?? 0
            pageIndexes[ObjectIdentifier(canvasView)] = pageIndex
            visibleCanvases[ObjectIdentifier(canvasView)] = WeakCanvasReference(canvasView)
            canvasView.drawing = drawing(for: pageIndex)
            configureAnnotationCanvas(canvasView, mode: parent.mode, role: .overlay)
            configureToolPicker(for: canvasView, visible: parent.mode == .annotate)
        }

        func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
            guard let canvasView = overlayView as? PKCanvasView else { return }
            let id = ObjectIdentifier(canvasView)
            toolPickers[id]?.removeObserver(canvasView)
            toolPickers[id] = nil
            pageIndexes[id] = nil
            visibleCanvases[id] = nil
        }

        func resetVisibleCanvasesIfNeeded(resetID: UUID, pdfView: PDFView) {
            guard resetID != lastResetID else { return }
            lastResetID = resetID
            pageDrawingData = parent.pdfPageDrawings
            visibleCanvases = visibleCanvases.filter { $0.value.canvasView != nil }
            for (id, reference) in visibleCanvases {
                guard let canvasView = reference.canvasView else { continue }
                let pageIndex = pageIndexes[id] ?? 0
                canvasView.drawing = drawing(for: pageIndex)
            }
            pdfView.layoutDocumentView()
        }

        func updateMode() {
            visibleCanvases = visibleCanvases.filter { $0.value.canvasView != nil }
            for reference in visibleCanvases.values {
                guard let canvasView = reference.canvasView else { continue }
                configureAnnotationCanvas(canvasView, mode: parent.mode, role: .overlay)
                configureToolPicker(for: canvasView, visible: parent.mode == .annotate)
            }
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard let pageIndex = pageIndexes[ObjectIdentifier(canvasView)] else { return }
            pageDrawingData[pageIndex] = canvasView.drawing.dataRepresentation()
            parent.onPageDrawingChanged(pageIndex, canvasView.drawing)
        }

        private func drawing(for pageIndex: Int) -> PKDrawing {
            let data = pageDrawingData[pageIndex] ?? parent.pdfPageDrawings[pageIndex] ?? legacyDrawingData(for: pageIndex)
            guard !data.isEmpty else { return PKDrawing() }
            return (try? PKDrawing(data: data)) ?? PKDrawing()
        }

        private func legacyDrawingData(for pageIndex: Int) -> Data {
            pageIndex == 0 ? parent.legacyDrawingData : Data()
        }

        private func configure(_ canvasView: PKCanvasView) {
            canvasView.delegate = self
            canvasView.isOpaque = false
            canvasView.backgroundColor = .clear
            canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 6)
            canvasView.isScrollEnabled = false
            canvasView.alwaysBounceVertical = false
            canvasView.alwaysBounceHorizontal = false
            configureAnnotationCanvas(canvasView, mode: parent.mode, role: .overlay)
            configureToolPicker(for: canvasView, visible: parent.mode == .annotate)
        }

        private func configureToolPicker(for canvasView: PKCanvasView, visible: Bool) {
            let id = ObjectIdentifier(canvasView)
            if toolPickers[id] == nil {
                let picker = PKToolPicker()
                picker.addObserver(canvasView)
                toolPickers[id] = picker
            }
            if visible {
                canvasView.becomeFirstResponder()
            } else {
                canvasView.resignFirstResponder()
            }
            toolPickers[id]?.setVisible(visible, forFirstResponder: canvasView)
        }
    }
}

private final class WeakCanvasReference {
    weak var canvasView: PKCanvasView?

    init(_ canvasView: PKCanvasView) {
        self.canvasView = canvasView
    }
}

struct ImageContentView: View {
    let url: URL
    let mode: AnnotationMode
    @Binding var drawing: PKDrawing
    let drawingResetID: UUID
    let onDrawingChanged: (PKDrawing) -> Void
    let onContentBoundsChanged: (CGRect) -> Void

    var body: some View {
        ImageAnnotationCanvasView(
            url: url,
            mode: mode,
            drawing: $drawing,
            drawingResetID: drawingResetID,
            onDrawingChanged: onDrawingChanged,
            onContentBoundsChanged: onContentBoundsChanged
        )
    }
}

struct ImageAnnotationCanvasView: UIViewRepresentable {
    let url: URL
    let mode: AnnotationMode
    @Binding var drawing: PKDrawing
    let drawingResetID: UUID
    let onDrawingChanged: (PKDrawing) -> Void
    let onContentBoundsChanged: (CGRect) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.isOpaque = true
        canvasView.backgroundColor = .systemBackground
        context.coordinator.updateCanvasDrawingIfNeeded(canvasView, drawing: drawing, resetID: drawingResetID)
        canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 6)
        canvasView.minimumZoomScale = 1
        canvasView.maximumZoomScale = 6
        canvasView.alwaysBounceVertical = true
        canvasView.alwaysBounceHorizontal = true
        configureAnnotationCanvas(canvasView, mode: mode, role: .scrollSurface)
        context.coordinator.configureImage(in: canvasView, url: url)
        context.coordinator.configureToolPicker(for: canvasView, visible: mode == .annotate)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        configureAnnotationCanvas(canvasView, mode: mode, role: .scrollSurface)
        context.coordinator.configureImage(in: canvasView, url: url)
        context.coordinator.configureToolPicker(for: canvasView, visible: mode == .annotate)
        context.coordinator.updateCanvasDrawingIfNeeded(canvasView, drawing: drawing, resetID: drawingResetID)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate, UIScrollViewDelegate {
        var parent: ImageAnnotationCanvasView
        private let imageView = UIImageView()
        private var toolPicker: PKToolPicker?
        private var displayedURL: URL?
        private var lastExternalDrawingData: Data?
        private var lastResetID: UUID?
        private var lastReportedContentBounds: CGRect = .zero

        init(parent: ImageAnnotationCanvasView) {
            self.parent = parent
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .systemBackground
        }

        func configureImage(in canvasView: PKCanvasView, url: URL) {
            if imageView.superview == nil {
                canvasView.insertSubview(imageView, at: 0)
            }

            if displayedURL != url {
                displayedURL = url
                imageView.image = UIImage(contentsOfFile: url.path)
            }

            let contentSize = imageView.image?.size ?? canvasView.bounds.size
            imageView.frame = CGRect(origin: .zero, size: contentSize)
            canvasView.contentSize = contentSize
            let contentBounds = CGRect(origin: .zero, size: contentSize)
            if contentBounds != lastReportedContentBounds {
                lastReportedContentBounds = contentBounds
                parent.onContentBoundsChanged(contentBounds)
            }
        }

        func configureToolPicker(for canvasView: PKCanvasView, visible: Bool) {
            if toolPicker == nil {
                let picker = PKToolPicker()
                picker.addObserver(canvasView)
                toolPicker = picker
            }

            if visible {
                canvasView.becomeFirstResponder()
            } else {
                canvasView.resignFirstResponder()
            }
            toolPicker?.setVisible(visible, forFirstResponder: canvasView)
        }

        func updateCanvasDrawingIfNeeded(_ canvasView: PKCanvasView, drawing: PKDrawing, resetID: UUID) {
            guard resetID != lastResetID || lastExternalDrawingData == nil else { return }
            let drawingData = drawing.dataRepresentation()
            if resetID != lastResetID {
                canvasView.drawing = drawing
                lastExternalDrawingData = drawingData
                lastResetID = resetID
                return
            }
            guard drawingData != lastExternalDrawingData else { return }
            canvasView.drawing = drawing
            lastExternalDrawingData = drawingData
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onDrawingChanged(canvasView.drawing)
        }
    }
}

private enum AnnotationCanvasRole {
    case overlay
    case scrollSurface
}

private func configureAnnotationCanvas(_ canvasView: PKCanvasView, mode: AnnotationMode, role: AnnotationCanvasRole) {
    applyDrawingPolicy(to: canvasView)
    canvasView.drawingGestureRecognizer.isEnabled = mode == .annotate

    switch role {
    case .overlay:
        canvasView.isUserInteractionEnabled = mode == .annotate
        canvasView.isScrollEnabled = false
    case .scrollSurface:
        canvasView.isUserInteractionEnabled = true
        canvasView.isScrollEnabled = true
    }
}

private func applyDrawingPolicy(to canvasView: PKCanvasView) {
    #if DEBUG
    canvasView.drawingPolicy = .anyInput
    #else
    canvasView.drawingPolicy = .pencilOnly
    #endif
}
