import Flutter
import UIKit

/// Barra de pestañas nativa (UITabBar) incrustada como platform view.
/// Compilada con el SDK de iOS 26+ sale con Liquid Glass sin más trabajo.
///
/// Canal `vinilo/tabbar_<id>`:
///   Dart → iOS: setSelected(int), setStyle({tint, unselectedTint, dark})
///   iOS → Dart: selected(int), height(double) con el alto que pide la barra,
///               frame([x, y, w, h]) con el rectángulo de la píldora para que
///               Flutter solo le entregue los toques que caen dentro y deje
///               pasar el resto al contenido de debajo.
final class NativeTabBarFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    NativeTabBarView(
      frame: frame,
      viewId: viewId,
      args: args as? [String: Any] ?? [:],
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class NativeTabBarView: NSObject, FlutterPlatformView, UITabBarDelegate {
  private let container: TabBarContainer
  private let tabBar = UITabBar()
  private let channel: FlutterMethodChannel
  private var lastFrame = CGRect.null
  private var lastHeight: CGFloat = 0

  init(frame: CGRect, viewId: Int64, args: [String: Any], messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "vinilo/tabbar_\(viewId)", binaryMessenger: messenger)
    container = TabBarContainer(frame: frame)
    super.init()

    container.backgroundColor = .clear
    container.tabBar = tabBar
    container.addSubview(tabBar)
    tabBar.delegate = self
    tabBar.backgroundColor = .clear
    apply(args)

    container.onLayout = { [weak self] in
      self?.reportHeight()
      self?.reportFrame()
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      switch call.method {
      case "setSelected":
        if let idx = call.arguments as? Int { self.select(idx) }
        result(nil)
      case "setStyle":
        self.apply(call.arguments as? [String: Any] ?? [:])
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { container }

  private func apply(_ args: [String: Any]) {
    if let items = args["items"] as? [[String: Any]] {
      tabBar.items = items.enumerated().map { index, item in
        let label = item["label"] as? String ?? ""
        let icon = item["icon"] as? String ?? "circle"
        let selectedIcon = item["selectedIcon"] as? String
        let tab = UITabBarItem(
          title: label,
          image: UIImage(systemName: icon),
          selectedImage: selectedIcon.flatMap { UIImage(systemName: $0) }
        )
        tab.tag = index
        return tab
      }
    }
    if let idx = args["selected"] as? Int { select(idx) }
    if let tint = args["tint"] as? NSNumber {
      tabBar.tintColor = UIColor(argb: tint.uint32Value)
    }
    if let tint = args["unselectedTint"] as? NSNumber {
      tabBar.unselectedItemTintColor = UIColor(argb: tint.uint32Value)
    }
    if let dark = args["dark"] as? Bool {
      container.overrideUserInterfaceStyle = dark ? .dark : .light
    }
  }

  private func select(_ index: Int) {
    guard let items = tabBar.items, index >= 0, index < items.count else { return }
    if tabBar.selectedItem !== items[index] { tabBar.selectedItem = items[index] }
  }

  /// Rectángulo que ocupan los botones (la píldora de vidrio los envuelve).
  /// En iOS 26 los botones ya no son hijos directos del UITabBar, así que se
  /// buscan en profundidad; si no aparece ningún UIControl se toma la vista
  /// más ancha que no ocupe toda la barra (la plataforma de vidrio).
  private func reportFrame() {
    var found = controls(in: tabBar)
    if found.isEmpty {
      found = tabBar.subviews.filter {
        !$0.isHidden && $0.frame.width > 40 && $0.frame.width < tabBar.bounds.width * 0.98
      }
    }
    guard !found.isEmpty else {
      #if DEBUG
      dumpHierarchy(tabBar, depth: 0)
      #endif
      return
    }
    var union = CGRect.null
    for view in found {
      guard let parent = view.superview else { continue }
      union = union.union(parent.convert(view.frame, to: container))
    }
    guard !union.isNull, union != lastFrame else { return }
    lastFrame = union
    channel.invokeMethod("frame", arguments: [union.minX, union.minY, union.width, union.height])
  }

  /// Alto que pide el UITabBar, zona segura de abajo incluida (83 pt en un
  /// iPhone con indicador de inicio). Flutter dimensiona la vista con él.
  private func reportHeight() {
    guard container.window != nil, container.bounds.width > 0 else { return }
    let height = tabBar.sizeThatFits(CGSize(width: container.bounds.width, height: 0)).height
    guard abs(height - lastHeight) >= 0.5 else { return }
    lastHeight = height
    channel.invokeMethod("height", arguments: Double(height))
  }

  private func controls(in view: UIView) -> [UIView] {
    var out: [UIView] = []
    for sub in view.subviews where !sub.isHidden {
      if sub is UIControl {
        out.append(sub)
      } else {
        out += controls(in: sub)
      }
    }
    return out
  }

  #if DEBUG
  private func dumpHierarchy(_ view: UIView, depth: Int) {
    guard depth < 4 else { return }
    let pad = String(repeating: "  ", count: depth)
    print("NativeTabBar \(pad)\(type(of: view)) \(view.frame)")
    for sub in view.subviews { dumpHierarchy(sub, depth: depth + 1) }
  }
  #endif

  // MARK: UITabBarDelegate

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    channel.invokeMethod("selected", arguments: item.tag)
  }
}

final class TabBarContainer: UIView {
  weak var tabBar: UITabBar?
  var onLayout: (() -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    tabBar?.frame = bounds
    onLayout?()
  }

  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    setNeedsLayout()
  }
}

extension UIColor {
  convenience init(argb: UInt32) {
    self.init(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255
    )
  }
}
