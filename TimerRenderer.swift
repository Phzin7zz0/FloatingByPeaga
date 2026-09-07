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
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        defer {
            CVPixelBufferUnlockBaseAddress(buffer, [])
        }

        guard let baseAddress =
                CVPixelBufferGetBaseAddress(buffer) else {
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
                CGImageAlphaInfo
                    .premultipliedFirst
                    .rawValue
        ) else {
            return nil
        }

        // Corrige orientação do CoreGraphics
        context.translateBy(
            x: 0,
            y: CGFloat(height)
        )

        context.scaleBy(
            x: 1,
            y: -1
        )

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

        let paragraphStyle =
            NSMutableParagraphStyle()

        paragraphStyle.alignment =
            .center

        let textAttributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    UIFont.monospacedDigitSystemFont(
                        ofSize: 105,
                        weight: .bold
                    ),

                .foregroundColor:
                    UIColor.white,

                .paragraphStyle:
                    paragraphStyle
            ]

        let textRect = CGRect(
            x: 0,
            y: 105,
            width: width,
            height: 150
        )

        text.draw(
            in: textRect,
            withAttributes: textAttributes
        )

        UIGraphicsPopContext()

        return buffer
    }
}
