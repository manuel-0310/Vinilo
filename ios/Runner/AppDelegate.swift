import Flutter
import Photos
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

/// Canal `vinilo/share` (`ShareService` en Dart):
/// - `share`: la hoja del sistema con el texto y el enlace.
/// - `shareImage`: la hoja del sistema con una imagen (PNG), el texto y el
///   enlace (WhatsApp, "Compartir imagen").
/// - `instagramStory`: abre Instagram con la imagen de fondo de una historia
///   (esquema `instagram-stories`, con el App ID de Meta). Devuelve false si
///   Instagram no está o no hay App ID, y Dart cae a `shareImage`.
/// - `saveImage`: guarda la imagen en Fotos (pide permiso de "agregar" la
///   primera vez). Devuelve true, o el error `denied` / `failed`.
/// En iPad la hoja se ancla al rectángulo del botón.
enum ShareChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "vinilo/share", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "share":
        result(present(items: textItems(args), args: args))
      case "shareImage":
        guard let image = image(args) else {
          result(false)
          return
        }
        result(present(items: [image] + textItems(args), args: args))
      case "instagramStory":
        result(instagramStory(args))
      case "saveImage":
        save(args, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func textItems(_ args: [String: Any]) -> [Any] {
    var items: [Any] = []
    if let text = args["text"] as? String, !text.isEmpty { items.append(text) }
    if let raw = args["url"] as? String, let url = URL(string: raw) { items.append(url) }
    return items
  }

  private static func png(_ args: [String: Any]) -> Data? {
    (args["png"] as? FlutterStandardTypedData)?.data
  }

  private static func image(_ args: [String: Any]) -> UIImage? {
    png(args).flatMap { UIImage(data: $0) }
  }

  private static func present(items: [Any], args: [String: Any]) -> Bool {
    guard !items.isEmpty, let presenter = topViewController() else { return false }
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
    return true
  }

  /// Historia de Instagram: la imagen va por el portapapeles (5 minutos) y
  /// el esquema abre el editor de historias con ella de fondo.
  private static func instagramStory(_ args: [String: Any]) -> Bool {
    guard let data = png(args),
      let appId = args["appId"] as? String, !appId.isEmpty,
      let url = URL(string: "instagram-stories://share?source_application=\(appId)"),
      UIApplication.shared.canOpenURL(url)
    else { return false }
    UIPasteboard.general.setItems(
      [["com.instagram.sharedSticker.backgroundImage": data]],
      options: [.expirationDate: Date().addingTimeInterval(5 * 60)]
    )
    UIApplication.shared.open(url)
    return true
  }

  private static func save(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let image = image(args) else {
      result(FlutterError(code: "failed", message: nil, details: nil))
      return
    }
    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        DispatchQueue.main.async { result(FlutterError(code: "denied", message: nil, details: nil)) }
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { ok, _ in
        DispatchQueue.main.async {
          result(ok ? true : FlutterError(code: "failed", message: nil, details: nil))
        }
      }
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
