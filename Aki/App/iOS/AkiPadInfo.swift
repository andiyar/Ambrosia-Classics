import PDFKit
import UIKit

/// The About box, the Release Notes viewer and the Handbook (`-[Controller showAboutBox:]` @ 0x327a,
/// `showReleaseNotes:` @ 0x358e, `showHandbook:` @ 0x33b2). Non-modal windows (or Preview) on the Mac; on
/// iPad, dismissible sheets with a Done button that pause nothing. While one is up the canvas takes no
/// input and the menu commands are off (the host checks `presentedViewController`).
@MainActor enum AkiPadInfo {
    /// `showAboutBox:`: the app name and version over the shipped `AboutCredits1.rtf` (preferred `.lproj`,
    /// falling back to English).
    static func about(controller: AkiController) -> UIViewController {
        let view = UIViewController()
        view.view.backgroundColor = .white
        let info = Bundle.main.infoDictionary ?? [:]
        let name = (info["CFBundleName"] as? String) ?? "Aki"
        let version = (info["CFBundleShortVersionString"] as? String) ?? ""
        let heading = UILabel()
        heading.text = name
        heading.font = .boldSystemFont(ofSize: 17)
        heading.textAlignment = .center
        heading.textColor = .black
        let versionLabel = UILabel()
        versionLabel.text = "Version \(version)"
        versionLabel.font = .systemFont(ofSize: 11)
        versionLabel.textAlignment = .center
        versionLabel.textColor = .darkGray
        let credits = textView()
        if let data = try? controller.assets.lproj("AboutCredits1.rtf"), let text = rtf(data) {
            credits.attributedText = text
        }
        let stack = UIStackView(arrangedSubviews: [heading, versionLabel, credits])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.view.addSubview(stack)
        let guide = view.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
        ])
        return sheet(view, title: "", style: .formSheet)
    }

    /// `showReleaseNotes:`: "Aki Release Notes" (`localizedStringForKey:`), the shipped `Release Notes.rtf`
    /// read-only in a scrolling text view — in Osaka-Mono when the bundle registered it (`UIAppFonts`),
    /// else Menlo (the font table rewritten in memory; the file is untouched).
    static func releaseNotes(controller: AkiController) -> UIViewController {
        let view = UIViewController()
        view.view.backgroundColor = .white
        let text = textView()
        text.frame = view.view.bounds
        text.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let url = controller.assets.url("Release Notes.rtf"), let data = try? Data(contentsOf: url),
           let notes = rtf(rtfWithAvailableFont(data)) {
            text.attributedText = notes
        }
        view.view.addSubview(text)
        return sheet(view, title: controller.assets.localized("Aki Release Notes"), style: .formSheet)
    }

    /// `showHandbook:`: the shipped `Aki Handbook.pdf` in PDFKit's `PDFView`; nil when the bundle lacks it.
    static func handbook(controller: AkiController) -> UIViewController? {
        guard let url = controller.assets.url("Aki Handbook.pdf"), let document = PDFDocument(url: url) else { return nil }
        let view = UIViewController()
        let pdf = PDFView(frame: view.view.bounds)
        pdf.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdf.autoScales = true
        pdf.document = document
        view.view.addSubview(pdf)
        return sheet(view, title: url.deletingPathExtension().lastPathComponent, style: .pageSheet)
    }

    // MARK: Helpers

    private static func sheet(_ content: UIViewController, title: String, style: UIModalPresentationStyle) -> UIViewController {
        content.title = title
        let done = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak content] _ in
            content?.dismiss(animated: true)
        })
        content.navigationItem.rightBarButtonItem = done
        let navigation = UINavigationController(rootViewController: content)
        navigation.modalPresentationStyle = style
        navigation.overrideUserInterfaceStyle = .light
        return navigation
    }

    private static func textView() -> UITextView {
        let text = UITextView()
        text.isEditable = false
        text.backgroundColor = .white
        text.textColor = .black
        return text
    }

    private static func rtf(_ data: Data) -> NSAttributedString? {
        try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf],
                                documentAttributes: nil)
    }

    /// The shipped RTF's font table names `Osaka-Mono`; when the bundle did not register it, the in-memory
    /// font-table entry becomes `Menlo` (the size lives in the body's `\fs26`, unchanged).
    private static func rtfWithAvailableFont(_ data: Data) -> Data {
        guard UIFont(name: "Osaka-Mono", size: 13) == nil, var rtf = String(data: data, encoding: .isoLatin1),
              let table = rtf.range(of: "{\\fonttbl"),
              let end = rtf.range(of: "}", range: table.upperBound..<rtf.endIndex) else { return data }
        rtf.replaceSubrange(table.lowerBound..<end.upperBound,
                            with: rtf[table.lowerBound..<end.upperBound].replacingOccurrences(of: "Osaka-Mono;", with: "Menlo;"))
        return rtf.data(using: .isoLatin1) ?? data
    }
}
