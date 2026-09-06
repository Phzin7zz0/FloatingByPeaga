import UIKit
import CoreVideo

enum TimerRenderer {

    static func createPixelBuffer(text: String) -> CVPixelBuffer? {

        let width = 640
        let height = 360

        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
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
            print("❌ Erro ao criar PixelBuffer:", status)
            return nil
        }

        CVPixelBufferLockBaseAddress(
            buffer,
            []
        )

        defer {
            CVPixelBufferUnlockBaseAddress(
                buffer,
                []
            )
        }

        guard let baseAddress =
                CVPixelBufferGetBaseAddress(buffer)
        else {
            print("❌ BaseAddress inválido")
            return nil
        }

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo:
                CGImageAlphaInfo.premultipliedFirst.rawValue |
                CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            print("❌ Não foi possível criar CGContext")
            return nil
        }

        // Fundo preto
        context.setFillColor(
            UIColor.black.cgColor
        )

        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )

        UIGraphicsPushContext(context)

        defer {
            UIGraphicsPopContext()
        }

        let paragraphStyle =
            NSMutableParagraphStyle()

        paragraphStyle.alignment = .center

        let font =
            UIFont.monospacedDigitSystemFont(
                ofSize: 100,
                weight: .bold
            )

        let textAttributes:
            [NSAttributedString.Key: Any] = [

                .font: font,

                .foregroundColor:
                    UIColor.white,

                .paragraphStyle:
                    paragraphStyle
            ]

        let rect = CGRect(
            x: 0,
            y: (height - 120) / 2,
            width: width,
            height: 120
        )

        text.draw(
            in: rect,
            withAttributes:
                textAttributes
        )

        return buffer
    }
}
