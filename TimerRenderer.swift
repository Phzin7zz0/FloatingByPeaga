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
            print("ERRO AO CRIAR PIXEL BUFFER")
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        defer {
            CVPixelBufferUnlockBaseAddress(buffer, [])
        }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            print("SEM BASE ADDRESS")
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
            print("ERRO AO CRIAR CONTEXT")
            return nil
        }

        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(x: 10, y: 10, width: width - 20, height: height - 20))

        UIGraphicsPushContext(context)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let textAttributes: [NSAttributedString.Key: Any] = [
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
            withAttributes: textAttributes
        )

        UIGraphicsPopContext()

        print("FRAME CRIADO:", text)

        return buffer
    }
}
