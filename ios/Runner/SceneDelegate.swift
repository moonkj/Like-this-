import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let windowScene = scene as? UIWindowScene,
          let window = windowScene.windows.first,
          let flutterVC = window.rootViewController as? FlutterViewController else {
      return
    }

    LikeThisCamera.setup(
      messenger: flutterVC.binaryMessenger,
      textureRegistry: flutterVC as FlutterTextureRegistry
    )
  }
}
