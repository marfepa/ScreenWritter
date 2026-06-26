import SwiftUI

/// Una vista nativa en SwiftUI que representa el icono de la aplicación ScreenWritter
/// siguiendo las tendencias de diseño de 2026 (glassmorfismo, gradientes de malla,
/// profundidad 3D y brillo de neón).
public struct AppIconView: View {
    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // 1. Fondo principal: Gradiente profundo índigo/violeta (Mesh Gradient simulado)
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.04, blue: 0.16),
                        Color(red: 0.02, green: 0.01, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Brillo de fondo sutil para dar ambiente
                RadialGradient(
                    colors: [
                        Color(red: 0.18, green: 0.10, blue: 0.45).opacity(0.35),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.6
                )
                
                // 2. Capa intermedia: Placa de vidrio flotante (Glassmorphism)
                ZStack {
                    // Sombra arrojada por el vidrio sobre el fondo para dar profundidad
                    RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                        .fill(Color.black.opacity(0.55))
                        .offset(y: size * 0.04)
                        .blur(radius: size * 0.035)
                    
                    // Cuerpo del vidrio con material translúcido
                    RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .opacity(0.9)
                    
                    // Destello interno/borde de refracción del vidrio
                    RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.06),
                                    Color.clear,
                                    Color.white.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: size * 0.007
                        )
                    
                    // 3. Trazo brillante (PencilKit overlay concept) y la punta del lápiz
                    GeometryReader { cardGeo in
                        let cardSize = min(cardGeo.size.width, cardGeo.size.height)
                        let strokeWidth = cardSize * 0.045
                        let neonColor = Color(red: 0.0, green: 0.85, blue: 1.0)
                        let glowColor = Color(red: 0.2, green: 0.5, blue: 1.0)
                        
                        ZStack {
                            // Sombra proyectada del trazo sobre el fondo oscuro
                            IconWavePath()
                                .stroke(
                                    Color.black.opacity(0.4),
                                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                                )
                                .offset(y: cardSize * 0.04)
                                .blur(radius: cardSize * 0.02)
                            
                            // Multi-capa de brillo neón (Glow)
                            IconWavePath()
                                .stroke(
                                    glowColor.opacity(0.4),
                                    style: StrokeStyle(lineWidth: strokeWidth * 2.2, lineCap: .round, lineJoin: .round)
                                )
                                .blur(radius: cardSize * 0.05)
                            
                            IconWavePath()
                                .stroke(
                                    neonColor.opacity(0.85),
                                    style: StrokeStyle(lineWidth: strokeWidth * 1.5, lineCap: .round, lineJoin: .round)
                                )
                                .blur(radius: cardSize * 0.015)
                            
                            // Línea sólida de neón
                            IconWavePath()
                                .stroke(
                                    LinearGradient(
                                        colors: [neonColor, Color.white],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                                )
                            
                            // Icono del lápiz minimalista apuntando al final del trazo
                            PencilTipView(scale: cardSize)
                                .offset(
                                    x: cardGeo.size.width * 0.70,
                                    y: cardGeo.size.height * 0.42
                                )
                        }
                    }
                    .padding(size * 0.08)
                }
                .frame(width: size * 0.70, height: size * 0.52)
                .offset(y: -size * 0.02)
            }
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            // Borde biselado del icono del app completo
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.clear,
                                Color.black.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size * 0.015
                    )
            )
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

/// Trazo minimalista que representa la anotación en el icono
struct IconWavePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let startPoint = CGPoint(
            x: rect.minX + rect.width * 0.12,
            y: rect.minY + rect.height * 0.62
        )
        path.move(to: startPoint)
        
        // Curva Bezier cúbica para simular un trazo orgánico y fluido
        let control1 = CGPoint(
            x: rect.minX + rect.width * 0.32,
            y: rect.minY + rect.height * 0.20
        )
        let control2 = CGPoint(
            x: rect.minX + rect.width * 0.55,
            y: rect.minY + rect.height * 0.90
        )
        let endPoint = CGPoint(
            x: rect.minX + rect.width * 0.70,
            y: rect.minY + rect.height * 0.48
        )
        
        path.addCurve(to: endPoint, control1: control1, control2: control2)
        return path
    }
}

/// Punta de lápiz minimalista en diagonal que se alinea con el trazo
struct PencilTipView: View {
    let scale: CGFloat
    
    var body: some View {
        let neonColor = Color(red: 0.0, green: 0.85, blue: 1.0)
        
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.white, neonColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: scale * 0.05, height: scale * 0.22)
            .rotationEffect(.degrees(32))
            // Brillo en el lápiz
            .shadow(color: neonColor.opacity(0.8), radius: scale * 0.02, x: 0, y: 0)
    }
}

#Preview {
    AppIconView()
        .frame(width: 320, height: 320)
        .padding()
        .background(Color(red: 0.05, green: 0.03, blue: 0.1))
}
