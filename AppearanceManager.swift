import SwiftUI
import Combine

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

    init() {
        self.backgroundColor = AppearanceManager.loadColor(key: "pipBackgroundColor") ?? .black
        self.textColor = AppearanceManager.loadColor(key: "pipTextColor") ?? .white
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

    // MARK: - Conversão pra uso no TimerRenderer (CGContext usa CGColor)

    var backgroundCGColor: CGColor {
        UIColor(backgroundColor).cgColor
    }

    var textCGColor: CGColor {
        UIColor(textColor).cgColor
    }
}
