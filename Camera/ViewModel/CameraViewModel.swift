
import AVFoundation
import CoreImage
import UIKit

// ViewModel用のプロトコル定義
protocol CameraViewModelDelegate: AnyObject {
    func didCapturePhoto(_ photo: UIImage)
}

class CameraViewModel: NSObject {
    
    weak var delegate: CameraViewModelDelegate?
    var isFlashOn: Bool = false
    
    // カメラのセッションを管理するプロパティ
    var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    
    // カメラの初期設定を行う
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // カメラデバイスの取得
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Error: No camera available")
            return
        }
        
        // フラッシュがサポートされているか確認
        if backCamera.hasFlash {
            print("This device supports flash.")
        } else {
            print("This device does not support flash.")
            // フラッシュがサポートされていない場合の処理
            return
        }
        
        // デバイス入力をセッションに追加
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
        } catch {
            print("Error: \(error)")
            return
        }
        
        // AVCaptureSessionの設定変更を開始
        captureSession.beginConfiguration()
        
        // photoOutputの初期化
        photoOutput = AVCapturePhotoOutput()
        
        // photoOutputの設定を追加
        photoOutput.isHighResolutionCaptureEnabled = false
        if #available(iOS 13.0, *) {
            photoOutput.maxPhotoQualityPrioritization = .balanced
        }
        
        // photoOutputをセッションに追加
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            print("Error: Unable to add photo output.")
            captureSession.commitConfiguration()
            return
        }
        
        // 設定変更を確定
        captureSession.commitConfiguration()
        
        // セッションを開始
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func createPhotoSettings() -> AVCapturePhotoSettings {
        print("createPhotoSettings()内のisFlashOn: \(isFlashOn)")
        let settings = AVCapturePhotoSettings()

        // フラッシュモードの設定
        settings.flashMode = isFlashOn ? .on : .off

        // フラッシュモードの確認
        print("設定されたフラッシュモード: \(settings.flashMode.rawValue)")

        // **photoOutputがフラッシュモードをサポートしているかを確認**
        if photoOutput.supportedFlashModes.contains(settings.flashMode) {
            print("Flash mode is supported by photoOutput")
        } else {
            print("Flash mode is not supported by photoOutput")
        }

        return settings
    }
    
    // 写真撮影時にフラッシュ機能実装
    func capturePhoto() {
        // フラッシュの状態を確認
        print("現在のフラッシュ状態: \(isFlashOn)")
        
        let settings = createPhotoSettings()
        
        // 確実にフラッシュモードが適用されるか確認
        print("フラッシュモード during capture: \(settings.flashMode.rawValue)")
        
        // 写真撮影を実行
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    
    // 撮影された写真をモノトーンに加工し、デリゲートに渡す
    func processCapturedPhoto(_ image: UIImage) {
        let fixedImage = fixImageOrientation(image)
        guard let ciImage = CIImage(image: fixedImage) else { return }
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        if let outputImage = filter?.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                let monoImage = UIImage(cgImage: cgImage)
                delegate?.didCapturePhoto(monoImage)
                
                // モノトーン画像をカメラロールに保存
                UIImageWriteToSavedPhotosAlbum(monoImage, nil, nil, nil)
            }
        }
    }
    
    // 画像の向きを修正する
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        // 画像の向きに応じて変換を行う
        let orientation = image.imageOrientation
        var transform = CGAffineTransform.identity

        switch orientation {
        case .down, .downMirrored:
            // 上下逆さま
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            // 左向き
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            // 右向き
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }

        // ミラーリングを防ぐ（上下・左右反転の場合）
        switch orientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }

        // コンテキストを作成して画像を描画
        guard let colorSpace = cgImage.colorSpace else { return image }
        guard let context = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: cgImage.bytesPerRow, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else {
            return image
        }

        context.concatenate(transform)
        
        // 向きに応じて描画する位置を設定
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        }

        // 新しいUIImageを作成
        guard let newCgImage = context.makeImage() else { return image }
        return UIImage(cgImage: newCgImage)
    }
}

// 写真が撮影された後に呼ばれるメソッドを実装するためのコード
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoData = photo.fileDataRepresentation(),
              let image = UIImage(data: photoData) else {
            print("Error: Unable to capture photo")
            return
        }
        
        // 撮影された写真をモノトーンに加工
        processCapturedPhoto(image)
    }
}
