
import AVFoundation
import CoreImage
import UIKit

// ViewModel用のプロトコル定義
protocol CameraViewModelDelegate: AnyObject {
    func didCapturePhoto(_ photo: UIImage)
    func updateFlashButtonIcon(isFlashOn: Bool)
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
            print("エラー: カメラが利用できません")
            return
        }

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
        photoOutput.isHighResolutionCaptureEnabled = false

        if #available(iOS 13.0, *) {
            photoOutput.maxPhotoQualityPrioritization = .balanced
        }

        // photoOutputをセッションに追加
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            print("エラー: 写真を追加できませんでした")
            captureSession.commitConfiguration()
            return
        }

        // 設定変更を確定
        captureSession.commitConfiguration()

        // セッションを開始
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    // 写真を撮影する際の設定
    func createPhotoSettings() -> AVCapturePhotoSettings {
        print("createPhotoSettings()内のisFlashOn: \(isFlashOn)")
        let settings = AVCapturePhotoSettings()

        // フラッシュモードの設定
        settings.flashMode = isFlashOn ? .on : .off

        // フラッシュモードの確認
        print("設定されたフラッシュモード: \(settings.flashMode.rawValue)")

        // **photoOutputがフラッシュモードをサポートしているかを確認**
        if photoOutput.supportedFlashModes.contains(settings.flashMode) {
            print("フラッシュモードをサポートしています")
        } else {
            print("フラッシュモードをサポートしていません")
        }

        return settings
    }
    
    // カメラで写真を撮影する処理
    func capturePhoto() {
        print("写真撮影を開始")

        let settings = AVCapturePhotoSettings()  // シンプルに設定を生成

        // 写真撮影を実行
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    //カメラのフロントとバックを切り替える関数
    func flipCamera() {
        // 現在の入力デバイスを取得
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
            return
        }

        // 切り替えるカメラデバイスを取得（バックカメラ → フロントカメラ or フロントカメラ → バックカメラ）
        let newCameraDevice: AVCaptureDevice?
        if currentInput.device.position == .back {
            newCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        } else {
            newCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }

        // 新しいカメラが取得できなかった場合は終了
        guard let newDevice = newCameraDevice else {
            return
        }

        do {
            // 新しいカメラの入力を作成
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            // セッションの設定を再構成
            captureSession.beginConfiguration()
            
            // 現在のカメラ入力を削除
            captureSession.removeInput(currentInput)
            
            // 新しいカメラ入力を追加
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            } else {
                print("エラー: 新しいカメラ入力を追加できませんでした")
            }
            
            // 設定変更を確定
            captureSession.commitConfiguration()
        } catch {
            print("Error: \(error)")
        }
    }
}
// 撮影した写真を処理するクラス
class PhotoProcessor {
    // モノトーン加工を行う静的メソッド
    static func applyMonoEffect(to image: UIImage) -> UIImage? {
        guard let fixedImage = fixImageOrientation(image),
              let ciImage = CIImage(image: fixedImage) else {
            return nil
        }

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

    // 画像の向きを修正
    private static func fixImageOrientation(_ image: UIImage) -> UIImage? {
        // すでに正しい向きならそのまま返す
        if image.imageOrientation == .up {
            return image
        }

        // 画像のコンテキストを作成
        guard let cgImage = image.cgImage else { return nil }
        let width = image.size.width
        let height = image.size.height
        var transform = CGAffineTransform.identity

        // 向きに応じてアフィン変換を設定
        switch image.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height).rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0).rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height).rotated(by: -.pi / 2)
        case .up, .upMirrored:
            break
        @unknown default:
            return image
        }

        // ミラー処理（反転）
        switch image.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0).scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0).scaledBy(x: -1, y: 1)
        default:
            break
        }

        // コンテキストの作成
        guard let colorSpace = cgImage.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else {
            return nil
        }

        context.concatenate(transform)

        // 描画範囲を設定し、画像を描画
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        // 新しいCGImageを作成し、UIImageに変換
        guard let newCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: newCGImage)
    }
    
    // 画像をDocumentディレクトリに保存する関数
    static func saveImageToDocumentDirectory(image: UIImage, imageName: String) {
        // DocumentディレクトリのURLを取得
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("ドキュメントディレクトリが見つかりませんでした")
            return
        }
        
        // 画像の保存先URLを作成
        let fileURL = documentsDirectory.appendingPathComponent("\(imageName).jpg")
        
        // 画像をJPEGデータに変換して保存
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
                print("画像が保存されました: \(fileURL)")
            } catch {
                print("画像の保存中にエラーが発生しました: \(error)")
            }
        }
    }
}

// 写真が撮影された後に呼ばれるコード
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,didFinishProcessingPhoto photo: AVCapturePhoto,error: Error?) {
        // エラーチェック
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }

        // 写真データの取得
        guard let photoData = photo.fileDataRepresentation(),
              let image = UIImage(data: photoData) else {
            print("エラー: 写真をキャプチャできませんでした")
            return
        }
        
        // 撮影後にフラッシュの状態を初期化（オフに戻す）
        isFlashOn = false
        
        // アイコンもオフの状態にリセット
        delegate?.updateFlashButtonIcon(isFlashOn: false)
        
        // フラッシュの物理的な状態もオフに
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("エラー: トーチが利用できません")
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = .off  // フラッシュを物理的にオフに
            device.unlockForConfiguration()
        } catch {
            print("エラー: トーチをオフにする際に問題が発生しました: \(error)")
        }

        // PhotoProcessorを使ってモノトーン加工を実行
        if let monoImage = PhotoProcessor.applyMonoEffect(to: image) {
            // モノトーン画像が正常に生成された場合
            delegate?.didCapturePhoto(monoImage)
            // カメラロールに保存
            UIImageWriteToSavedPhotosAlbum(monoImage, nil, nil, nil)
            // ドキュメントディレクトリに保存
            PhotoProcessor.saveImageToDocumentDirectory(image: monoImage, imageName: "capturedPhoto")
        } else {
            print("エラー: 画像の処理に失敗しました")
        }
    }
}
