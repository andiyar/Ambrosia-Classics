// btx-predecode <Bubble Trouble X Contents/Resources> <output-directory> — decodes every band of the game's
// QuickTime-JPEG PICTs with the real CodecImage (ImageIO) and writes `<key>.rgba` files for Windows'
// `CodecImage.registerPrecomputed` (plan W0.5, DECISIONS D16.1; staged as Data/Decoded/). Idempotent: existing
// *.rgba in the output directory are replaced. Mac-only; on other platforms it only says so.
#if canImport(ImageIO)
import BTXWinKit
import Foundation

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write(Data("usage: btx-predecode <Bubble Trouble X Contents/Resources> <out dir>\n".utf8))
    exit(2)
}
do {
    let written = try BTXPredecode.run(resourcesDirectory: URL(fileURLWithPath: args[1]),
                                       outputDirectory: URL(fileURLWithPath: args[2]))
    for picture in written {
        print("\(picture.file) PICT \(picture.id): \(picture.keys.count) band\(picture.keys.count == 1 ? "" : "s")")
    }
    print("btx-predecode: \(written.count) PICTs, \(written.reduce(0) { $0 + $1.keys.count }) bands")
} catch {
    FileHandle.standardError.write(Data("btx-predecode: \(error)\n".utf8))
    exit(1)
}
#else
import Foundation

FileHandle.standardError.write(Data("btx-predecode is Mac-only (it decodes with ImageIO)\n".utf8))
exit(1)
#endif
