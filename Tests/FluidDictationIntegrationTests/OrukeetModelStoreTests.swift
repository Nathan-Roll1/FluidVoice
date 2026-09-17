@testable import FluidVoice_Debug
import Foundation
import XCTest

#if arch(arm64)
final class OrukeetModelStoreTests: XCTestCase {
    func testRejectsIncompleteInstallation() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertFalse(OrukeetModelStore.installed(at: missing))
        XCTAssertThrowsError(try OrukeetModelStore.load(from: missing))
    }

    func testRejectsCorruptArchiveBeforeCreatingInstallation() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = root.appendingPathComponent("corrupt.zip")
        try Data("not a model archive".utf8).write(to: archive)
        let destination = root.appendingPathComponent("installed")
        XCTAssertThrowsError(try OrukeetModelStore.installArchive(at: archive, to: destination))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    /// Opt-in integration check using the actual pinned Hugging Face archive.
    func testCompilesPortableBundleAndDetectsMissingComponent() throws {
        guard let path = ProcessInfo.processInfo.environment["ORUKEET_COREML_ARCHIVE"] else {
            throw XCTSkip("Set ORUKEET_COREML_ARCHIVE to the pinned baseline ZIP")
        }
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: destination) }
        try OrukeetModelStore.installArchive(at: URL(fileURLWithPath: path), to: destination)
        XCTAssertTrue(OrukeetModelStore.installed(at: destination))
        XCTAssertEqual(try OrukeetModelStore.load(from: destination).vocabulary.count, 8192)
        try FileManager.default.removeItem(at: destination.appendingPathComponent("Encoder.mlmodelc"))
        XCTAssertFalse(OrukeetModelStore.installed(at: destination))
        XCTAssertThrowsError(try OrukeetModelStore.load(from: destination))
    }
}
#endif
