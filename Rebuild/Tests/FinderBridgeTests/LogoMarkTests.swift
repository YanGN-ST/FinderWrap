import XCTest
import AppKit
@testable import FinderBridge

final class LogoMarkTests: XCTestCase {
    func testArtworkGridMatchesTheAppIcon() {
        XCTAssertEqual(LogoMark.designSize, CGSize(width: 512, height: 512))
        XCTAssertEqual(LogoMark.artBounds, CGRect(x: 79, y: 128, width: 341, height: 262))
        XCTAssertEqual(LogoMark.strokeWidth, 32)
        XCTAssertEqual(LogoMark.cellCornerRadius, 16)
        XCTAssertEqual(LogoMark.artAspectRatio, 341.0 / 262.0, accuracy: 0.0001)
    }

    func testWrappedIconsSitInsideTheArtworkBounds() {
        XCTAssertEqual(LogoMark.cells.count, 5)
        for cell in LogoMark.cells {
            XCTAssertEqual(cell.size, CGSize(width: 62, height: 60))
            XCTAssertTrue(LogoMark.artBounds.contains(cell), "\(cell) escapes \(LogoMark.artBounds)")
        }
        // Three icons on the top row, two on the bottom row.
        XCTAssertEqual(LogoMark.cells.prefix(3).map(\.midY).filter { $0 == 158 }.count, 3)
        XCTAssertEqual(LogoMark.cells.suffix(2).map(\.midY).filter { $0 == 358 }.count, 2)
    }

    func testArrowCentreLinesCoverTheWrapShape() {
        XCTAssertEqual(LogoMark.shaftPath().boundingBox,
                       CGRect(x: 132.5, y: 159, width: 265, height: 179))
        XCTAssertEqual(LogoMark.headPath().boundingBox,
                       CGRect(x: 95, y: 330, width: 75, height: 42))
    }

    func testCellPathMatchesItsRect() {
        let cell = LogoMark.cells[0]
        XCTAssertEqual(LogoMark.cellPath(cell).boundingBox, cell)
    }

    func testFitTransformKeepsTheArtworkCentred() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 100)
        let transformed = LogoMark.artBounds.applying(LogoMark.fitTransform(in: rect))
        XCTAssertEqual(transformed.midX, rect.midX, accuracy: 0.001)
        XCTAssertEqual(transformed.midY, rect.midY, accuracy: 0.001)
        // The artwork is wider than it is tall, so the width fills the square.
        XCTAssertEqual(transformed.width, 100, accuracy: 0.001)
        XCTAssertEqual(transformed.height, 100 * 262.0 / 341.0, accuracy: 0.001)
    }

    func testStatusItemImageIsATemplateAtStatusSize() {
        let image = LogoMark.statusItemImage(height: 17)
        XCTAssertEqual(image.size.height, 17)
        XCTAssertEqual(image.size.width, 22) // 17 × 341/262, rounded
        XCTAssertTrue(image.isTemplate)
        XCTAssertEqual(image.accessibilityDescription, "FinderWrap")

        let larger = LogoMark.statusItemImage(height: 24, accessibilityDescription: "Wrap")
        XCTAssertEqual(larger.size, NSSize(width: 31, height: 24))
        XCTAssertEqual(larger.accessibilityDescription, "Wrap")
    }
}
