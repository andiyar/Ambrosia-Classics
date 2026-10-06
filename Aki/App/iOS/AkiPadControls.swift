import UIKit

/// The Aqua-era controls the overlay dialogs are built from (plan C4): drawn in code, close to the 2008
/// look — the parchment background, a title bar, push buttons (white-to-light-grey, the default one blue),
/// checkboxes and top-aligned wrapping labels. All black-on-light regardless of the system appearance (the
/// Mac app forces Aqua too).
enum AquaStyle {
    static let text = UIColor.black

    /// The nib font: `name` at `size` when the iPad has it, else the system font (bold when the nib's
    /// name says so). Lucida Grande is not on iPadOS, so in practice this is the system font.
    static func font(name: String?, size: CGFloat) -> UIFont {
        if let name, let font = UIFont(name: name, size: size) { return font }
        if let name, name.localizedCaseInsensitiveContains("bold") { return .boldSystemFont(ofSize: size) }
        return .systemFont(ofSize: size)
    }
}

/// `PaperBackgroundView`: `paper.png` stretched into the view's bounds.
final class PaperView: UIImageView {
    init(frame: CGRect, paper: UIImage?) {
        super.init(frame: frame)
        image = paper
        contentMode = .scaleToFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("PaperView is built in code") }
}

/// A wrapping label whose text starts at the TOP of its frame, as an AppKit wrapping text field draws.
final class TopAlignedLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let fitted = textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
        super.drawText(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: min(rect.height, fitted.height)))
    }
}

/// The movable-modal title bar: a light grey gradient with the window title centred.
final class AquaTitleBar: UIView {
    static let height: CGFloat = 22
    private let label = UILabel()

    init(width: CGFloat, title: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: Self.height))
        isOpaque = true
        label.text = title
        label.font = .systemFont(ofSize: 13)
        label.textColor = AquaStyle.text
        label.textAlignment = .center
        label.frame = bounds.insetBy(dx: 8, dy: 0)
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("AquaTitleBar is built in code") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let colors = [UIColor(white: 0.93, alpha: 1).cgColor, UIColor(white: 0.80, alpha: 1).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: bounds.height), options: [])
        }
        UIColor(white: 0.55, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: bounds.height - 0.5, width: bounds.width, height: 0.5))
    }
}

/// An Aqua push button. `frame` is the visible bezel: a rounded rect, white to light grey with a grey
/// border; the default button (Return) is blue with white text. Highlighted while pressed.
final class AquaButton: UIControl {
    let title: String
    let isDefault: Bool
    private let font: UIFont

    init(frame: CGRect, title: String, font: UIFont, isDefault: Bool) {
        self.title = title
        self.isDefault = isDefault
        self.font = font
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        accessibilityLabel = title
        accessibilityTraits = .button
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("AquaButton is built in code") }

    override var isHighlighted: Bool {
        didSet { setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let bezel = bounds.insetBy(dx: 0.5, dy: 0.5)
        let radius = min(bezel.height / 2, 6)
        let path = UIBezierPath(roundedRect: bezel, cornerRadius: radius)
        let top: UIColor, bottom: UIColor, border: UIColor, ink: UIColor
        if isDefault {
            top = isHighlighted ? UIColor(red: 0.30, green: 0.52, blue: 0.86, alpha: 1) : UIColor(red: 0.55, green: 0.75, blue: 0.98, alpha: 1)
            bottom = isHighlighted ? UIColor(red: 0.12, green: 0.36, blue: 0.75, alpha: 1) : UIColor(red: 0.20, green: 0.48, blue: 0.90, alpha: 1)
            border = UIColor(red: 0.12, green: 0.30, blue: 0.62, alpha: 1)
            ink = .white
        } else {
            top = isHighlighted ? UIColor(white: 0.80, alpha: 1) : .white
            bottom = isHighlighted ? UIColor(white: 0.68, alpha: 1) : UIColor(white: 0.86, alpha: 1)
            border = UIColor(white: 0.52, alpha: 1)
            ink = AquaStyle.text
        }
        context.saveGState()
        path.addClip()
        let colors = [top.cgColor, bottom.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: bezel.minY), end: CGPoint(x: 0, y: bezel.maxY), options: [])
        }
        context.restoreGState()
        border.setStroke()
        path.lineWidth = 1
        path.stroke()
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: ink]
        let size = (title as NSString).size(withAttributes: attributes)
        (title as NSString).draw(at: CGPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2),
                                 withAttributes: attributes)
    }
}

/// An Aqua checkbox: a small rounded box (checked = blue with a white tick) and its title to the right;
/// a tap anywhere on it toggles `isOn`.
final class AquaCheckbox: UIControl {
    var isOn = false {
        didSet { setNeedsDisplay() }
    }
    private let title: String
    private let font: UIFont

    init(frame: CGRect, title: String, font: UIFont) {
        self.title = title
        self.font = font
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        isAccessibilityElement = true
        accessibilityLabel = title
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("AquaCheckbox is built in code") }

    override var isHighlighted: Bool {
        didSet { setNeedsDisplay() }
    }

    override var accessibilityValue: String? {
        get { isOn ? "1" : "0" }
        set {}
    }

    @objc private func toggle() {
        isOn.toggle()
    }

    override func draw(_ rect: CGRect) {
        let side: CGFloat = 13
        let box = CGRect(x: 2.5, y: (bounds.height - side) / 2, width: side, height: side).integral.insetBy(dx: 0.5, dy: 0.5)
        let path = UIBezierPath(roundedRect: box, cornerRadius: 3)
        if isOn {
            (isHighlighted ? UIColor(red: 0.12, green: 0.36, blue: 0.75, alpha: 1) : UIColor(red: 0.22, green: 0.50, blue: 0.92, alpha: 1)).setFill()
        } else {
            (isHighlighted ? UIColor(white: 0.78, alpha: 1) : .white).setFill()
        }
        path.fill()
        UIColor(white: isOn ? 0.25 : 0.50, alpha: 1).setStroke()
        path.lineWidth = 1
        path.stroke()
        if isOn {
            let tick = UIBezierPath()
            tick.move(to: CGPoint(x: box.minX + 3, y: box.midY))
            tick.addLine(to: CGPoint(x: box.minX + 5.5, y: box.maxY - 3))
            tick.addLine(to: CGPoint(x: box.maxX - 2.5, y: box.minY + 2.5))
            tick.lineWidth = 2
            tick.lineCapStyle = .round
            tick.lineJoinStyle = .round
            UIColor.white.setStroke()
            tick.stroke()
        }
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: AquaStyle.text]
        let size = (title as NSString).size(withAttributes: attributes)
        (title as NSString).draw(at: CGPoint(x: box.maxX + 5, y: bounds.midY - size.height / 2), withAttributes: attributes)
    }
}
