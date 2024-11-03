## 実行環境
- macOS Sequoia 15.0.1
- Xcode 16.0
- iPhone16 iOS18.0.1

## 開発ツール
- Swift 6.0
- SwiftUI
- AVFoundation
- CoreImage
- UIKit

## アプリケーションの仕様
このアプリはカメラ機能を利用して写真を撮影します。カメラのインバック切り替え、フラッシュのオンオフ、グリッド線追加、撮影した写真の保存先選択などが可能です。
- AVFoundationを使用してカメラ操作を実装
- CoreImageを使用してモノクロフィルタを適用
- UIKitを使用してユーザーインターフェースを構築

## 要件
- iOS 15.0以降
- カメラへのアクセス許可が必要
- フォトライブラリへのアクセス許可が必要
- Xcode 15.4以降

## 実行手順
1. リポジトリをクローン
　　　git clone https://github.com/Ryokisil/cameraApp.git
2. Xcodeでプロジェクトを開き、ターゲットを選択してビルド
3. シミュレータまたは実機でアプリを実行
