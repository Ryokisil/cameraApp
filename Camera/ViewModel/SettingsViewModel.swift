
import Foundation

// トグルのオンオフ状態を管理するViewModel
class SettingsViewModel: ObservableObject {
    // UserDefaultsのキー
    private let gridFeatureKey = "gridFeatureEnabled"

    // @Publishedを使いトグル状態をSwiftUI側と連携
    @Published var isGridFeatureEnabled: Bool {
        didSet {
            // トグルの状態が変更されたらUserDefaultsに保存
            UserDefaults.standard.set(isGridFeatureEnabled, forKey: gridFeatureKey)
        }
    }

    // 初期化時にUserDefaultsから状態を読み込む
    init() {
        let savedState = UserDefaults.standard.bool(forKey: gridFeatureKey)
        print("Saved grid feature state: \(savedState)") // デバッグログ
        self.isGridFeatureEnabled = savedState
    }
}

