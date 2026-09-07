import UIKit
import CoreVideo

enum TimerRenderer {

    static func createPixelBuffer(text: String) -> CVPixelBuffer? {

        let width = 640
        let height = 360

        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        var pixelBuffer: CVPixelBuffer?

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess,
              let buffer = pixelBuffer else {
            print("❌ ERRO CRIANDO BUFFER")
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }

        // IMPORTANTE: CGContext criado direto sobre a memória do
        // CVPixelBuffer tem origem no canto inferior esquerdo (padrão
        // do Core Graphics). O buffer de vídeo/AVSampleBufferDisplayLayer
        // espera a linha 0 no topo, e o UIKit também desenha texto
        // assumindo origem no topo. Sem esse flip, tudo sai espelhado
        // verticalmente (de cabeça para baixo).
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)

        // TESTE: FUNDO VERMELHO FORTE
        context.setFillColor(UIColor.red.cgColor)
        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )

        UIGraphicsPushContext(context)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(
                ofSize: 100,
                weight: .bold
            ),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        text.draw(
            in: CGRect(
                x: 0,
                y: 120,
                width: width,
                height: 120
            ),
            withAttributes: textAttributes
        )

        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(buffer, [])

        print("🟥 BUFFER CRIADO:", text)

        return buffer
    }
}