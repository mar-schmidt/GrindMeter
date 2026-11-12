// Local visual QA renderer for tests/render_layout.lua; no WoW or window automation.
import AppKit
import Foundation

let source = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = URL(fileURLWithPath: CommandLine.arguments[2])
let doc = try JSONSerialization.jsonObject(with: Data(contentsOf: source)) as! [String: Any]
let width = doc["width"] as! Int, height = doc["height"] as! Int
let scale = 2
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width * scale, pixelsHigh: height * scale, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let transform = NSAffineTransform(); transform.scale(by: CGFloat(scale)); transform.concat()
NSColor(calibratedRed: 0.045, green: 0.055, blue: 0.075, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
func color(_ v: Any?, default fallback: NSColor = .white) -> NSColor {
    guard let a = v as? [Double], a.count >= 3 else { return fallback }
    return NSColor(calibratedRed: a[0], green: a[1], blue: a[2], alpha: a.count > 3 ? a[3] : 1)
}
for node in doc["nodes"] as! [[String: Any]] {
    let x = node["x"] as! Double, y = node["y"] as! Double
    let w = node["w"] as! Double, h = node["h"] as! Double
    let rect = NSRect(x: x, y: Double(height) - y - h, width: w, height: h)
    if node["bg"] != nil { color(node["bg"]).setFill(); rect.fill() }
    if let text = node["text"] as? String {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = node["align"] as? String == "CENTER" ? .center : node["align"] as? String == "RIGHT" ? .right : .left
        paragraph.lineBreakMode = .byWordWrapping
        let size = node["fontSize"] as? Double ?? 12
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size), .foregroundColor: color(node["color"]), .paragraphStyle: paragraph]
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }
}
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: destination)
print(destination.path)
