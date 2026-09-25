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
    // Hoja nativa de compartir (ver ShareChannel, abajo).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "vinilo.share") {
      ShareChannel.register(with: registrar.messenger())
    }
  }
}

/// Canal `vinilo/share`: abre la hoja de compartir del sistema
/// (`UIActivityViewController`) con el texto y el enlace que manda Dart
/// (`ShareService`). En iPad la ancla al rectángulo del botón.
enum ShareChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "vinilo/share", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "share", let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      var items: [Any] = []
      if let text = args["text"] as? String, !text.isEmpty { items.append(text) }
      if let raw = args["url"] as? String, let url = URL(string: raw) { items.append(url) }
      guard !items.isEmpty, let presenter = topViewController() else {
        result(false)
        return
      }
      let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
      if let popover = sheet.popoverPresentationController {
        popover.sourceView = presenter.view
        if let x = args["x"] as? Double, let y = args["y"] as? Double,
          let w = args["w"] as? Double, let h = args["h"] as? Double
        {
          popover.sourceRect = CGRect(x: x, y: y, width: w, height: h)
        } else {
          let bounds = presenter.view.bounds
          popover.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
        }
      }
      presenter.present(sheet, animated: true)
      result(true)
    }
  }

  /// El controlador de más arriba de la ventana principal, para presentar
  /// la hoja encima de cualquier otra que esté abierta.
  private static func topViewController() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    var top = (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}
