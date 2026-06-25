import PencilKit
import SwiftUI

struct AnnotationWorkspaceView: View {
    let session: AnnotationSession
    @Bindable var store: SessionStore

    @State private var mode: AnnotationMode = .navigate
    @State private var drawing = PKDrawing()
    @State private var canvasBounds: CGRect = .zero
    @State private var exportedFile: ExportedFile?
    @State private var exportErrorMessage: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ContentRenderer(source: session.contentSource)
                    .ignoresSafeArea()

                AnnotationCanvasRepresentable(
                    drawing: $drawing,
                    mode: mode,
                    onDrawingChanged: { newDrawing in
                        store.updateDrawing(for: session.id, drawingData: newDrawing.dataRepresentation())
                    }
                )
                .allowsHitTesting(mode == .annotate)
                .ignoresSafeArea()

                VStack {
                    HStack {
                        Picker("Modo", selection: $mode) {
                            ForEach(AnnotationMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                        .accessibilityIdentifier("modePicker")

                        Spacer()

                        Button {
                            drawing = PKDrawing()
                            store.updateDrawing(for: session.id, drawingData: Data())
                        } label: {
                            Label("Limpiar", systemImage: "eraser")
                        }

                        Menu {
                            Button {
                                exportPNG()
                            } label: {
                                Label("PNG", systemImage: "photo")
                            }

                            Button {
                                exportPDF()
                            } label: {
                                Label("PDF", systemImage: "doc.richtext")
                            }
                            .disabled(session.contentKind != .pdf)
                        } label: {
                            Label("Exportar", systemImage: "square.and.arrow.up")
                        }
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding()

                    Spacer()
                }
            }
            .onAppear {
                canvasBounds = proxy.frame(in: .local)
                restoreDrawing()
            }
            .onChange(of: proxy.size) { _, newSize in
                canvasBounds = CGRect(origin: .zero, size: newSize)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            store.importFiles(urls)
            return true
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportedFile) { file in
            ShareSheet(items: [file.url])
        }
        .alert("No se pudo exportar", isPresented: Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }

    private func restoreDrawing() {
        guard !session.drawingData.isEmpty else {
            drawing = PKDrawing()
            return
        }

        do {
            drawing = try PKDrawing(data: session.drawingData)
        } catch {
            drawing = PKDrawing()
        }
    }

    private func exportPNG() {
        do {
            exportedFile = ExportedFile(url: try AnnotationExporter.exportImage(
                session: session,
                drawing: drawing,
                contentImage: previewImage(for: session.contentSource),
                canvasBounds: canvasBounds
            ))
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func exportPDF() {
        do {
            exportedFile = ExportedFile(url: try AnnotationExporter.exportPDF(session: session, drawing: drawing, canvasBounds: canvasBounds))
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func previewImage(for source: ContentSource) -> UIImage? {
        guard case .image(let url) = source else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

private struct ExportedFile: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
