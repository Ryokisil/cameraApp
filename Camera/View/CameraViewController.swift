//画面1 アプリ起動時カメラを起動する画面

import UIKit
import AVFoundation
import SwiftUI

// UIViewControllerをSwiftUIで使えるようにラップする
struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // 特に更新処理がない場合はここは空でもOK
    }
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
        // ViewModelのインスタンス
        var viewModel: CameraViewModel!
        
        // UIパーツ: シャッターボタン
        private let shutterButton: UIButton = {
            let button = UIButton(type: .custom)
            button.backgroundColor = .white
            button.layer.cornerRadius = 35   // ボタンを丸くする（直径70）
            button.layer.borderWidth = 5     // 外側に枠を追加
            button.layer.borderColor = UIColor.lightGray.cgColor  // 枠の色
            return button
        }()
    
        private var previewLayer: AVCaptureVideoPreviewLayer!
    
        // カウントダウン表示用のラベル
        private let countdownLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.boldSystemFont(ofSize: 80)
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isHidden = true  // 初期状態では非表示
            return label
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // ViewModelの初期化と設定
            viewModel = CameraViewModel()
            viewModel.delegate = self
            
            // カメラの設定をViewModelに任せる
            viewModel.setupCamera()
            
            // プレビューレイヤーのセットアップ
            setupCameraPreview()
            
            // UIのセットアップ
            setupUI()
            
            // シャッターボタンにアクションを設定
            shutterButton.addTarget(self, action: #selector(didTapShutterButton), for: .touchUpInside)
        }
    
        // カメラプレビューのセットアップ
        private func setupCameraPreview() {
            previewLayer = AVCaptureVideoPreviewLayer(session: viewModel.captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)  // レイヤーをビューの一番後ろに追加
        }
        
        // UIのセットアップ処理
        private func setupUI() {
            view.addSubview(shutterButton)
            view.addSubview(countdownLabel)
            shutterButton.translatesAutoresizingMaskIntoConstraints = false
            countdownLabel.translatesAutoresizingMaskIntoConstraints = false
            // シャッターボタンのレイアウト
            NSLayoutConstraint.activate([
                shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                shutterButton.widthAnchor.constraint(equalToConstant: 70),
                shutterButton.heightAnchor.constraint(equalToConstant: 70),
                // カウントダウンラベルのレイアウト
                countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                countdownLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
        
    // シャッターボタン押下時のアクション
    @objc private func didTapShutterButton() {
        startCountdown()  // カウントダウンを開始
    }

    // カウントダウンを開始する
    private func startCountdown() {
        countdownLabel.isHidden = false
        countdown(from: 3)  // 3秒からカウントダウン開始
    }

    // カウントダウン処理
    private func countdown(from count: Int) {
        countdownLabel.text = "\(count)"
        
        if count > 0 {
            // 1秒後に次のカウントダウン
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.countdown(from: count - 1)
            }
        } else {
            // カウントダウンが終了したら写真を撮影
            countdownLabel.isHidden = true
            viewModel.capturePhoto()  // ViewModelに写真撮影を依頼
        }
    }
}

    // カメラ撮影結果を受け取るためのデリゲート
    extension CameraViewController: CameraViewModelDelegate {
        func didCapturePhoto(_ photo: UIImage) {
            // 撮影した写真をモノトーンに加工した後に画面遷移
            let photoVC = PhotoViewController()
            photoVC.capturedImage = photo
            navigationController?.pushViewController(photoVC, animated: true)
        }
    }
