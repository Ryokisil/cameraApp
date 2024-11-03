// 撮った写真を表示する画面

import UIKit
import Photos

// CameraViewControllerDelegateの実装
class PhotoDetailViewController: UIViewController {
    
    var image: UIImage? // 表示する画像を保持するプロパティ
    var imageView: UIImageView!
    var fetchResult: PHFetchResult<PHAsset>!
    var currentIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        fetchPhotosFromCameraRoll()
        setupUI()  // UI セットアップを呼び出す
        displayImage(at: currentIndex, in: imageView)
    }
    
    // UIを設定するメソッド
    private func setupUI() {
        // UIImageViewの設定
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        // 閉じるボタン
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("閉じる", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        // 閉じるボタンのレイアウト
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // スワイプジェスチャーの追加
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
        
        // 下スワイプで閉じるジェスチャー
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    // カメラロールから写真を取得
    private func fetchPhotosFromCameraRoll() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }
    
    // 指定されたインデックスの写真を表示
    private func displayImage(at index: Int, in imageView: UIImageView) {
        let asset = fetchResult.object(at: index)
        let targetSize = CGSize(width: view.bounds.width * UIScreen.main.scale, height: view.bounds.height * UIScreen.main.scale)
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { image, _ in
            imageView.image = image
        }
    }
    
    // 左右スワイプジェスチャーのアクション
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            // 前の写真へ移動（左スワイプで左に戻る）
            if currentIndex > 0 {
                currentIndex -= 1
                animateTransition(to: currentIndex, direction: .left)
            }
        case .right:
            // 次の写真へ移動（右スワイプで右に進む）
            if currentIndex < fetchResult.count - 1 {
                currentIndex += 1
                animateTransition(to: currentIndex, direction: .right)
            }
        default:
            break
        }
    }

    private func animateTransition(to index: Int, direction: UISwipeGestureRecognizer.Direction) {
        // アニメーションの設定
        let transitionOptions: UIView.AnimationOptions = (direction == .left) ? .transitionFlipFromRight : .transitionFlipFromLeft

        UIView.transition(with: imageView, duration: 0.3, options: [transitionOptions], animations: {
            self.displayImage(at: index, in: self.imageView)
        }, completion: nil)
    }
    
    // デリゲートメソッド：サムネイルがタップされたときに呼ばれる
    func didTapThumbnail(with image: UIImage) {
        self.image = image
    }
    
    // 閉じるボタンのアクション
    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    // スワイプダウンジェスチャーのアクション
    @objc private func handleSwipeDown() {
        dismiss(animated: true, completion: nil)
    }
}
