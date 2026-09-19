import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    
    // Set minimum desktop window constraints: 1100 x 720
    self.minSize = NSSize(width: 1100, height: 720)
    
    // Initial desktop window size: 1440 x 900 centered
    let initialSize = NSSize(width: 1440, height: 900)
    if let screen = self.screen ?? NSScreen.main {
      let screenRect = screen.visibleFrame
      let x = screenRect.origin.x + (screenRect.width - initialSize.width) / 2.0
      let y = screenRect.origin.y + (screenRect.height - initialSize.height) / 2.0
      self.setFrame(NSRect(x: x, y: y, width: initialSize.width, height: initialSize.height), display: true)
    } else {
      self.setContentSize(initialSize)
      self.center()
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
