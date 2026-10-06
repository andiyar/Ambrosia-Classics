import Foundation
import HectorGraphics
import XCTest

/// Off Apple there is no ImageIO, so `CodecImage.decode` answers only from precomputed RGBA (plan btx-windows W0.5,
/// DECISIONS D16.1): the BTX QuickTime-JPEG bands, decoded once on the Mac by `btx-predecode` into the directory
/// named by `HECTORKIT_DECODED_DIR`. `ensureRegistered()` loads it once per process (a global's lazy initializer
/// is thread-safe); unset → XCTSkip naming the variable. On the Mac this is a no-op: `decode` never consults the
/// registry there, so Mac counts and behaviour are unchanged.
enum DecodedImages {
    static let variable = "HECTORKIT_DECODED_DIR"

    static func ensureRegistered() throws {
        #if !canImport(ImageIO)
        try registration.get()
        #endif
    }
}

#if !canImport(ImageIO)
private let registration: Result<Void, any Error> = Result {
    guard let value = ProcessInfo.processInfo.environment[DecodedImages.variable], !value.isEmpty else {
        throw XCTSkip("\(DecodedImages.variable) unset — off Apple, set it to btx-predecode's output directory")
    }
    try CodecImage.registerPrecomputed(directory: URL(fileURLWithPath: value, isDirectory: true))
}
#endif
