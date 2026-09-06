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
            print("❌ ERRO AO CRIAR PIXEL BUFFER")
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            print("❌ SEM BASE ADDRESS")
            return nil
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            print("❌ ERRO AO CRIAR CONTEXT")
            return nil
        }

        // Fundo
        context.setFillColor(
            red: 0.05,
            green: 0.05,
            blue: 0.05,
            alpha: 1.0
        )

        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )

        // Caixa vermelha - TESTE VISUAL
        context.setFillColor(
            red: 1,
            green: 0,
            blue: 0,
            alpha: 1
        )

        context.fill(
            CGRect(
                x: 10,
                y: 10,
                width: width - 20,
                height: height - 20
            )
        )

        // Texto
        UIGraphicsPushContext(context)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributesText: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(
                ofSize: 110,
                weight: .bold
            ),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let textRect = CGRect(
            x: 0,
            y: 110,
            width: width,
            height: 140
        )

        text.draw(
            in: textRect,
            withAttributes: attributesText
        )

        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(buffer, [])

        print("✅ FRAME CRIADO:", text)

        return buffer
    }
}
