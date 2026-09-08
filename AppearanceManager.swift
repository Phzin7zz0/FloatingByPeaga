import SwiftUI
import Combine

enum TimerFont: String, CaseIterable, Identifiable {
    case system = "Padrão"
    case courier = "Courier"
    case menlo = "Menlo"
    case avenirNext = "Avenir Next"
    case futura = "Futura"
    case chalkduster = "Chalkduster"
    case typewriter = "American Typewriter"

    var id: String { rawValue }

    var fontName: String? {
        switch self {
        case .system: return nil
        case .courier: return "Courier-Bold"
        case .menlo: return "Menlo-Bold"
        case .avenirNext: return "AvenirNext-Bold"
        case .futura: return "Futura-Bold"
        case .chalkduster: return "Chalkduster"
        case .typewriter: return "AmericanTypewriter-Bold"
        }
    }

    func uiFont(size: CGFloat) -> UIFont {
        if let fontName = fontName,
           let font = UIFont(name: fontName, size: size) {
            return font
        }
        return UIFont.monospacedDigitSystemFont(ofSize: size, weight: .bold)
    }

    func swiftUIFont(size: CGFloat) -> Font {
        if let fontName = fontName {
            return .custom(fontName, size: size)
        }
        return .system(size: size, weight: .bold, design: .monospaced)
    }
}

final class AppearanceManager: ObservableObject {

    @Published var backgroundColor: Color {
        didSet {
            saveColor(backgroundColor, key: "pipBackgroundColor")
        }
    }

    @Published var textColor: Color {
        didSet {
            saveColor(textColor, key: "pipTextColor")
        }
    }

    @Published var selectedFont: TimerFont {
        didSet {
            UserDefaults.standard.set(selectedFont.rawValue, forKey: "pipSelectedFont")
        }
    }

    init() {
        self.backgroundColor = AppearanceManager.loadColor(key: "pipBackgroundColor") ?? .black
        self.textColor = AppearanceManager.loadColor(key: "pipTextColor") ?? .white

        let savedFontRaw = UserDefaults.standard.string(forKey: "pipSelectedFont")
        self.selectedFont = TimerFont(rawValue: savedFontRaw ?? "") ?? .system
    }

    // MARK: - Persistência (Color não é Codable, então salvamos como componentes RGBA)

    private func saveColor(_ color: Color, key: String) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let components = [Double(r), Double(g), Double(b), Double(a)]
        UserDefaults.standard.set(components, forKey: key)
    }

    private static func loadColor(key: String) -> Color? {
        guard let components = UserDefaults.standard.array(forKey: key) as? [Double],
              components.count == 4 else {
            return nil
        }

        return Color(
            red: components[0],
            green: components[1],
            blue: components[2],
            opacity: components[3]
        )
    }
}
