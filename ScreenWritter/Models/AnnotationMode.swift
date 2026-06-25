import Foundation

enum AnnotationMode: String, CaseIterable, Identifiable {
    case navigate
    case annotate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .navigate:
            "Navegar"
        case .annotate:
            "Anotar"
        }
    }
}
