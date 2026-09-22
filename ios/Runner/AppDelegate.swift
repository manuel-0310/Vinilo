import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Barra de pestañas nativa (Liquid Glass en iOS 26+), ver NativeTabBar.swift.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "vinilo.tabbar") {
      registrar.register(
        NativeTabBarFactory(messenger: registrar.messenger()),
        withId: "vinilo/tabbar"
      )
    }
  }
}
