import PencilKit
import SwiftUI

struct AnnotationCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let mode: AnnotationMode
    let onDrawingChanged: (PKDrawing) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        canvasView.drawing = drawing
        canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 6)
        canvasView.alwaysBounceVertical = false
        applyDrawingPolicy(to: canvasView)
        canvasView.isUserInteractionEnabled = mode == .annotate
        context.coordinator.configureToolPicker(for: canvasView, visible: mode == .annotate)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        applyDrawingPolicy(to: canvasView)
        canvasView.isUserInteractionEnabled = mode == .annotate

        if canvasView.drawing.dataRepresentation() != drawing.dataRepresentation() {
            canvasView.drawing = drawing
        }

        context.coordinator.configureToolPicker(for: canvasView, visible: mode == .annotate)
    }

    private func applyDrawingPolicy(to canvasView: PKCanvasView) {
        #if DEBUG
        canvasView.drawingPolicy = .anyInput
        #else
        canvasView.drawingPolicy = .pencilOnly
        #endif
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: AnnotationCanvasRepresentable
        private var toolPicker: PKToolPicker?

        init(parent: AnnotationCanvasRepresentable) {
            self.parent = parent
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

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onDrawingChanged(canvasView.drawing)
        }
    }
}
