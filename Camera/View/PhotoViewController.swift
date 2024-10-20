//画面2 撮影した写真を表示する画面

import UIKit

class PhotoViewController: UIViewController {
    
    var capturedImage: UIImage!
    
    // 画像表示ビューと終了ボタン
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("終了", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        
        view.backgroundColor = .white
        
        // UIのセットアップ
        setupUI()
        
        // 撮影した画像を表示
        if let capturedImage = capturedImage {
            imageView.image = capturedImage
        } else {
            print("Error: capturedImage is nil")
        }
    }
    
    // UIのセットアップ処理
    private func setupUI() {
        view.addSubview(imageView)
        view.addSubview(closeButton)
        
        // レイアウト設定
        imageView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 100),
            closeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // 終了ボタン押下時のアクション
    @objc private func didTapCloseButton() {
        // 画面1に戻る
        navigationController?.popViewController(animated: true)
    }
}
