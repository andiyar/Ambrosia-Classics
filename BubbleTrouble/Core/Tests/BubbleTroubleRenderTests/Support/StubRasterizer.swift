import BubbleTroubleCore
import BubbleTroubleRender

/// A `TextRasterizer` for headless tests: records each call and draws nothing (system fonts are the App's).
final class StubRasterizer: TextRasterizer {
    struct Call: Equatable {
        let text: String, font: String, size: Int, rgb: UInt32, h: Int, v: Int, centredIn: QDRect?
    }
    private(set) var calls: [Call] = []

    func rasterize(_ s: String, font: String, size: Int, rgb: UInt32, into: inout RGBAImage,
                   at: (h: Int, v: Int), centredIn: QDRect?) {
        calls.append(Call(text: s, font: font, size: size, rgb: rgb, h: at.h, v: at.v, centredIn: centredIn))
    }

    func width(_ s: String, font: String, size: Int) -> Int { 6 * s.count }
}
