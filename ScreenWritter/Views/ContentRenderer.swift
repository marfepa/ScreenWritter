import PDFKit
import SwiftUI
import WebKit

struct ContentRenderer: View {
    let source: ContentSource

    var body: some View {
        switch source {
        case .web(let url):
            WebContentView(url: url)
        case .pdf(let url):
            PDFContentView(url: url)
        case .image(let url):
            ImageContentView(url: url)
        }
    }
}

struct WebContentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}

struct PDFContentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document?.documentURL != url {
            pdfView.document = PDFDocument(url: url)
        }
    }
}

struct ImageContentView: View {
    let url: URL

    var body: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                if let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
                        .background(Color(.systemBackground))
                } else {
                    ContentUnavailableView("Imagen no disponible", systemImage: "photo.badge.exclamationmark")
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .background(Color(.systemBackground))
        }
    }
}
