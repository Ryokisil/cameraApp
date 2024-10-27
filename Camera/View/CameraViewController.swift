//画面1 アプリ起動時カメラを起動する画面

import UIKit
import AVFoundation
import SwiftUI

// UIViewControllerをSwiftUIで使えるようにする
struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // 特に更新処理がないのでこのまま
    }
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
        // ViewModelのインスタンス
        var viewModel: CameraViewModel!
        var isFlashOn = false
        private var previewLayer: AVCaptureVideoPreviewLayer!
        var captureSession: AVCaptureSession?
        var videoPreviewLayer: AVCaptureVideoPreviewLayer?
        
        // シャッターボタン
        private let shutterButton: UIButton = {
            let button = UIButton(type: .custom)
            button.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.86, alpha: 1.0)
            button.layer.cornerRadius = 35
            button.layer.borderWidth = 5
            button.layer.borderColor = UIColor.lightGray.cgColor
            return button
        }()
        // インバックカメラ切り替えボタンのラベル
        private let flipButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "camera.rotate"), for: .normal)  // カメラ切り替え用のアイコン
            button.tintColor = UIColor(red: 0.75, green: 0.85, blue: 1.0, alpha: 1.0)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
        // フラッシュボタンのラベル
        private let flashButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal) // 初期はフラッシュOFFのアイコン
            button.tintColor = UIColor(red: 0.75, green: 1.0, blue: 0.85, alpha: 1.0)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
    
        // カウントダウン表示用のラベル
        private let countdownLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.boldSystemFont(ofSize: 80)
            label.textColor = UIColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isHidden = true  // 初期状態では非表示
            return label
        }()
    
        // 設定用の歯車アイコン
        private let settingsButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "gearshape"), for: .normal) // 歯車アイコン
            button.tintColor = UIColor(red: 0.9, green: 0.8, blue: 1.0, alpha: 1.0)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        
        // アプリ起動時のみviewDidLoadで初期設定を行う
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // ViewModelの初期化と設定
            viewModel = CameraViewModel()
            viewModel.delegate = self
            // AVCaptureSession の初期化
            captureSession = AVCaptureSession()
            
            guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
            
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                captureSession?.addInput(input)
                
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                captureSession?.addOutput(videoOutput)
                
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                videoPreviewLayer?.videoGravity = .resizeAspectFill
                videoPreviewLayer?.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer!)
                
                DispatchQueue.global(qos: .userInitiated).async {
                        self.captureSession?.startRunning()
                }
                
            } catch {
                print("カメラの設定中にエラーが発生しました: \(error)")
            }
            
            // カメラの設定をViewModelに任せる
            viewModel.setupCamera()
            
            // プレビューレイヤーのセットアップ
            setupCameraPreview()
            
            // UIのセットアップ
            setupUI()
            
            // シャッターボタンにアクションを設定
            shutterButton.addTarget(self, action: #selector(didTapShutterButton), for: .touchUpInside)
            // フラッシュボタンのアクションを設定
            flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
            //インバックカメラ切り替えアクション設定
            flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
            
            // アプリ起動時はフラッシュをオフに設定
            isFlashOn = false
            flashButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        }
        // カメラのフレームごとに呼ばれる
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // 映像フレームごとに処理を行う
        }
    
        // カメラプレビューのセットアップ
        private func setupCameraPreview() {

            // プレビュー用のレイヤーを設定
            previewLayer = AVCaptureVideoPreviewLayer(session: viewModel.captureSession)
            // 解像度に応じたアスペクト比の変更を適用
            switch viewModel.captureSession.sessionPreset {
            case .photo: // 4:3
                previewLayer.videoGravity = .resizeAspect  // 4:3
            case .high, .medium: // 16:9
                previewLayer.videoGravity = .resizeAspectFill  // 16:9
            default:
                previewLayer.videoGravity = .resizeAspect  // デフォルトは4:3
            }
            
            // プレビューの位置とサイズを設定
            let previewHeight = view.bounds.height * 0.8
            previewLayer.frame = CGRect(x: 0, y: 50, width: view.bounds.width, height: previewHeight)
            
            // プレビューを画面にフィットさせカメラレイヤーを1番下に設置
            view.layer.sublayers?.removeAll()  // これで古いレイヤーを削除
            view.layer.insertSublayer(previewLayer, at: 0)
        }
    
        func restartSessionAfterResolutionChange() {
            viewModel.captureSession?.stopRunning()  // セッションを停止
            viewModel.captureSession?.beginConfiguration()

            // 必要な解像度設定処理がここに入る
            viewModel.captureSession?.commitConfiguration()
            
            viewModel.captureSession?.startRunning()  // セッションを再スタート
        }

        
        // UIのセットアップ
        private func setupUI() {
            view.addSubview(shutterButton)    // 撮影ボタン
            view.addSubview(flashButton)      // フラッシュボタン
            view.addSubview(countdownLabel)   // カウントダウンラベル
            view.addSubview(flipButton)       // フリップボタン
            view.addSubview(settingsButton)   // 歯車ボタン

            shutterButton.translatesAutoresizingMaskIntoConstraints = false
            countdownLabel.translatesAutoresizingMaskIntoConstraints = false
            flashButton.translatesAutoresizingMaskIntoConstraints = false

            // シャッターボタンのレイアウト
            NSLayoutConstraint.activate([
                shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: +2),
                shutterButton.widthAnchor.constraint(equalToConstant: 70),
                shutterButton.heightAnchor.constraint(equalToConstant: 70)
            ])

            // フラッシュボタンのレイアウト（シャッターボタンの左側に配置）
            NSLayoutConstraint.activate([
                flashButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
                flashButton.trailingAnchor.constraint(equalTo: shutterButton.leadingAnchor, constant: -20),
                flashButton.widthAnchor.constraint(equalToConstant: 50),
                flashButton.heightAnchor.constraint(equalToConstant: 50)
            ])

            // カウントダウンラベルを画面の中央に配置したい
            NSLayoutConstraint.activate([
                countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                countdownLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            
            // フリップボタンのレイアウト
            NSLayoutConstraint.activate([
                flipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),  // 画面上部に配置
                flipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),  // 右端に配置
                flipButton.widthAnchor.constraint(equalToConstant: 50),
                flipButton.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            // 歯車ボタンのレイアウト
            NSLayoutConstraint.activate([
                settingsButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                settingsButton.widthAnchor.constraint(equalToConstant: 30),
                settingsButton.heightAnchor.constraint(equalToConstant: 30)
            ])
            
            // タップ時に設定画面へ遷移
            settingsButton.addTarget(self, action: #selector(didTapSettingsButton), for: .touchUpInside)
        }
    // 初回撮影後に再度カメラプレビュー画面に戻ったらそれ以降はviewWillAppearで状態管理する
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // カメラ画面が再度表示されるたびにフラッシュ状態をリセット
        isFlashOn = false
        updateFlashButtonIcon(isFlashOn: isFlashOn)
    }
    
    // フラッシュボタンのアイコンを更新する
    func updateFlashButtonIcon(isFlashOn: Bool) {
        let flashIconName = isFlashOn ? "bolt.fill" : "bolt.slash.fill"
        flashButton.setImage(UIImage(systemName: flashIconName), for: .normal)
    }
        
    // シャッターボタン押下時のアクション
    @objc private func didTapShutterButton() {
        startCountdown()
    }

    // カウントダウンを開始する
    private func startCountdown() {
        countdownLabel.isHidden = false
        countdown(from: 3)
    }

    // カウントダウン処理
    private func countdown(from count: Int) {
        countdownLabel.text = "\(count)"
        
        if count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.countdown(from: count - 1)
            }
        } else {
            // カウントダウンが終了したら写真を撮影
            countdownLabel.isHidden = true
            viewModel.capturePhoto()  // ViewModelに写真撮影を依頼
        }
    }
    // フラッシュボタン設置
    @objc func toggleFlash() {
        // フラッシュの点灯/消灯を制御
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("エラー: カメラが利用できないか、またはトーチがサポートされていません")
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            // 現在のフラッシュ状態に応じてトーチモードを設定
            if isFlashOn {
                device.torchMode = .off  // フラッシュをオフに
            } else {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)  // フラッシュをオンに
            }
            
            device.unlockForConfiguration()
            
            // フラッシュの状態をトグル
            isFlashOn.toggle()
            
            // アイコンの更新
            flashButton.setImage(UIImage(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill"), for: .normal)
            
        } catch {
            print("トーチの切り替え中にエラーが発生しました: \(error)")
        }
    }
    
    // カメラ切り替え時ボタン設置と切り替え時にアニメーション追加
    @objc func flipButtonTapped() {
        // フェードアウトアニメーション
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.0  // 画面を一度透明にする
        }) { _ in
            // カメラの切り替えを行う
            self.viewModel.flipCamera()
            
            UIView.animate(withDuration: 0.3) {
                self.view.alpha = 1.0  // 画面を元に戻す
            }
        }
    }
    
    @objc private func didTapSettingsButton() {
        // 設定画面へ遷移
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
}

    // カメラ撮影結果を受け取る
    extension CameraViewController: CameraViewModelDelegate {
        func didCapturePhoto(_ photo: UIImage) {
            // 撮影した写真をモノトーンに加工した後に画面遷移
            let photoVC = PhotoViewController()
            photoVC.capturedImage = photo
            navigationController?.pushViewController(photoVC, animated: true)
        }
    }
