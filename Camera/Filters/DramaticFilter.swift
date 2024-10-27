// ドラマチック加工

import UIKit
import CoreImage

class DramaticFilter {
    static func apply(to image: UIImage) -> UIImage? {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIHighlightShadowAdjust")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.0, forKey: "inputHighlightAmount")
        filter?.setValue(0.2, forKey: "inputShadowAmount")
        
        if let outputImage = filter?.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}
