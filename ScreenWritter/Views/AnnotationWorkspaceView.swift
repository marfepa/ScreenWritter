import PencilKit
import SwiftUI

struct AnnotationWorkspaceView: View {
    let session: AnnotationSession
    @Bindable var store: SessionStore

    @State private var mode: AnnotationMode = .navigate
    @State private var drawing = PKDrawing()
    @State private var pdfPageDrawings: [Int: Data] = [:]
    @State private var contentBounds: CGRect = .zero
    @State private var exportedFile: ExportedFile?
    @State private var exportErrorMessage: String?
    @State private var draftCache = AnnotationDraftCache()
    @State private var drawingResetID = UUID()

    var body: some View {
        VStack(spacing: 0) {
            annotationToolbar

            ZStack(alignment: .bottomTrailing) {
                ContentRenderer(
                    source: session.contentSource,
                    mode: mode,
                    drawing: $drawing,
                    pdfPageDrawings: $pdfPageDrawings,
                    drawingResetID: drawingResetID,
                    legacyPDFDrawingData: legacyPDFDrawingData,
                    onDrawingChanged: { newDrawing in
                        scheduleDrawingSave(newDrawing)
                    },
                    onPDFPageDrawingChanged: { pageIndex, newDrawing in
                        schedulePDFPageDrawingSave(pageIndex: pageIndex, drawing: newDrawing)
                    },
                    onImageContentBoundsChanged: updateContentBounds
                )

                VStack(alignment: .trailing, spacing: 16) {
                    FloatingClearButton(action: clearDrawings)
                    floatingModeControl
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            restoreDrawings()
            drawingResetID = UUID()
        }
        .onDisappear {
            flushDrawings()
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

    private var annotationToolbar: some View {
        HStack {
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

            Spacer()
        }
        .padding(12)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var floatingModeControl: some View {
        FloatingAnnotationModePicker(mode: $mode)
    }

    private func restoreDrawings() {
        if session.drawingData.isEmpty {
            drawing = PKDrawing()
        } else {
            drawing = (try? PKDrawing(data: session.drawingData)) ?? PKDrawing()
        }

        pdfPageDrawings = session.pdfPageDrawingData
        draftCache.drawingData = drawing.dataRepresentation()
        draftCache.pdfPageDrawingData = session.pdfPageDrawingData
    }

    private func clearDrawings() {
        drawing = PKDrawing()
        pdfPageDrawings = [:]
        draftCache.clear()
        drawingResetID = UUID()
        store.clearDrawings(for: session.id)
    }

    private func scheduleDrawingSave(_ newDrawing: PKDrawing) {
        draftCache.updateDrawing(newDrawing)
    }

    private func schedulePDFPageDrawingSave(pageIndex: Int, drawing: PKDrawing) {
        draftCache.updatePDFPageDrawing(pageIndex: pageIndex, drawing: drawing)
    }

    private func updateContentBounds(_ bounds: CGRect) {
        guard contentBounds != bounds else { return }
        contentBounds = bounds
    }

    private func flushDrawings() {
        store.updateDrawing(for: session.id, drawingData: draftCache.drawingData)
        for (pageIndex, drawingData) in draftCache.pdfPageDrawingData {
            store.updatePDFPageDrawing(for: session.id, pageIndex: pageIndex, drawingData: drawingData)
        }
    }

    private func exportPNG() {
        do {
            flushDrawings()
            exportedFile = ExportedFile(url: try AnnotationExporter.exportImage(
                session: session,
                drawing: exportDrawing,
                contentImage: previewImage(for: session.contentSource),
                canvasBounds: exportBounds
            ))
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func exportPDF() {
        do {
            flushDrawings()
            exportedFile = ExportedFile(url: try AnnotationExporter.exportPDF(
                session: session,
                pdfPageDrawingData: draftCache.pdfPageDrawingData
            ))
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func previewImage(for source: ContentSource) -> UIImage? {
        guard case .image(let url) = source else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private var exportBounds: CGRect {
        contentBounds == .zero ? UIScreen.main.bounds : contentBounds
    }

    private var exportDrawing: PKDrawing {
        guard !draftCache.drawingData.isEmpty else { return drawing }
        return (try? PKDrawing(data: draftCache.drawingData)) ?? drawing
    }

    private var legacyPDFDrawingData: Data {
        session.drawingData
    }
}

private struct FloatingClearButton: View {
    let action: () -> Void

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 16) {
                button
                    .glassEffect(.regular.tint(.red.opacity(0.10)).interactive(), in: .capsule)
            }
        } else {
            fallbackButton
        }
        #else
        fallbackButton
        #endif
    }

    private var fallbackButton: some View {
        button
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.red.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 8)
    }

    private var button: some View {
        Button(role: .destructive, action: action) {
            Label {
                Text("Limpiar")
                    .font(.callout.weight(.semibold))
            } icon: {
                Image(systemName: "eraser")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.red)
            .frame(height: 48)
            .padding(.horizontal, 16)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("clearAnnotationsButton")
    }
}

private struct FloatingAnnotationModePicker: View {
    @Binding var mode: AnnotationMode

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 16) {
                picker
                    .padding(8)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
        } else {
            fallbackPicker
        }
        #else
        fallbackPicker
        #endif
    }

    private var fallbackPicker: some View {
        picker
            .padding(8)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 8)
    }

    private var picker: some View {
        Picker("Modo", selection: $mode) {
            ForEach(AnnotationMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 240)
        .accessibilityIdentifier("modePicker")
    }
}

private struct ExportedFile: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private final class AnnotationDraftCache {
    var drawingData = Data()
    var pdfPageDrawingData: [Int: Data] = [:]

    func updateDrawing(_ drawing: PKDrawing) {
        drawingData = drawing.dataRepresentation()
    }

    func updatePDFPageDrawing(pageIndex: Int, drawing: PKDrawing) {
        pdfPageDrawingData[pageIndex] = drawing.dataRepresentation()
    }

    func clear() {
        drawingData = Data()
        pdfPageDrawingData = [:]
    }
}
