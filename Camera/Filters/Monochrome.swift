// モノトーン加工

import UIKit
import CoreImage

class MonochromeFilter {
    static func apply(to image: UIImage) -> UIImage? {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        if let outputImage = filter?.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}
