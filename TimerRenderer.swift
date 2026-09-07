import Foundation
import UIKit
import CoreVideo
import CoreMedia

final class TimerRenderer {

    static func createPixelBuffer(
        text: String,
        size: CGSize = CGSize(width: 600, height: 220)
    ) -> CVPixelBuffer? {

        var pixelBuffer: CVPixelBuffer?

        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let result = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard result == kCVReturnSuccess,
              let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        defer {
            CVPixelBufferUnlockBaseAddress(buffer, [])
        }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            return nil
        }

        // Fundo preto
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // Desenha o texto
        UIGraphicsPushContext(context)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let font = UIFont.monospacedDigitSystemFont(
            ofSize: 95,
            weight: .bold
        )

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let rect = CGRect(
            x: 0,
            y: (size.height - 115) / 2,
            width: size.width,
            height: 115
        )

        (text as NSString).draw(
            in: rect,
            withAttributes: attributes
        )

        UIGraphicsPopContext()

        return buffer
    }
}