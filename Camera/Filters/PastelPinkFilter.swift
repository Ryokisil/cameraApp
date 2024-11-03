// パステルピンク加工

import UIKit
import CoreImage

class PastelPinkFilter {
    static func apply(to image: UIImage) -> UIImage? {
        let ciImage = CIImage(image: image)
        
        // パステルピンクのフィルターを適用
        let colorOverlayFilter = CIFilter(name: "CIColorMonochrome")
        colorOverlayFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        colorOverlayFilter?.setValue(CIColor(red: 1.0, green: 0.8, blue: 0.8), forKey: kCIInputColorKey) // パステルピンク色 (#ffcccc)
        colorOverlayFilter?.setValue(0.4, forKey: kCIInputIntensityKey) // 強度を調整 (0.0 ～ 1.0)

        if let outputImage = colorOverlayFilter?.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}
