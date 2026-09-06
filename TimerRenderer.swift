import UIKit
import CoreVideo

enum TimerRenderer {

    static func createPixelBuffer(text: String) -> CVPixelBuffer? {

        let width = 640
        let height = 360

        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
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
            print("Erro ao criar PixelBuffer")
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        defer {
            CVPixelBufferUnlockBaseAddress(buffer, [])
        }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            print("BaseAddress inválido")
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
            print("Erro ao criar CGContext")
            return nil
        }

        // FUNDO PRETO
        context.setFillColor(UIColor.black.cgColor)
        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )

        // Borda para teste
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(4)

        context.stroke(
            CGRect(
                x: 2,
                y: 2,
                width: width - 4,
                height: height - 4
            )
        )

        UIGraphicsPushContext(context)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(
                ofSize: 120,
                weight: .bold
            ),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let textRect = CGRect(
            x: 0,
            y: 100,
            width: width,
            height: 150
        )

        // DESENHA O CRONÔMETRO
        text.draw(
            in: textRect,
            withAttributes: textAttributes
        )

        // Texto pequeno para debug
        let debugAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(
                ofSize: 25,
                weight: .medium
            ),
            .foregroundColor: UIColor.green,
            .paragraphStyle: paragraphStyle
        ]

        "FLOATING TIMER".draw(
            in: CGRect(
                x: 0,
                y: 260,
                width: width,
                height: 40
            ),
            withAttributes: debugAttributes
        )

        UIGraphicsPopContext()

        return buffer
    }
}
