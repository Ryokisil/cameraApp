//カメラの動作確認テストコード

import XCTest
@testable import Camera

final class CameraTests: XCTestCase {

    var cameraViewModel: CameraViewModel!

        override func setUpWithError() throws {
            cameraViewModel = CameraViewModel()
            
            // カメラのセットアップを行う
            cameraViewModel.setupCamera()
            
            // cameraViewModelがnilでないことを確認
            XCTAssertNotNil(cameraViewModel, "cameraViewModelの初期化に失敗しています")
            
            // captureSessionとphotoOutputが正しく初期化されているか確認
            XCTAssertNotNil(cameraViewModel.captureSession, "captureSessionの初期化に失敗しています")
            XCTAssertNotNil(cameraViewModel.photoOutput, "photoOutputの初期化に失敗しています")
        }

        override func tearDownWithError() throws {
            cameraViewModel = nil
        }

    // カメラセッションが正しく設定されているかを確認するテスト
    func testCameraSessionIsConfigured() throws {
        cameraViewModel.setupCamera()
        XCTAssertNotNil(cameraViewModel.captureSession, "カメラセッションがnilです")
        XCTAssertTrue(cameraViewModel.captureSession?.isRunning == true, "カメラセッションが起動していません")
    }

    // 写真撮影のプロセスが正常に進むかを確認するテスト
    func testPhotoCapture() throws {
        let expectation = self.expectation(description: "写真が正常に撮影されたか確認")

        // モックのデリゲートを作成
        class MockDelegate: CameraViewModelDelegate {
            var photoCaptured = false
            func didCapturePhoto(_ photo: UIImage) {
                photoCaptured = true
            }
        }

        let mockDelegate = MockDelegate()
        cameraViewModel.delegate = mockDelegate

        // 撮影をシミュレート
        cameraViewModel.capturePhoto()

        // 非同期処理が終わるのを待つ
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertTrue(mockDelegate.photoCaptured, "写真が正常に撮影されていません")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
