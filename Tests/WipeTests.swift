@testable import Wipe
import XCTest

// MARK: - CleaningColor

final class CleaningColorTests: XCTestCase {
    func testAllCasesOrder() {
        XCTAssertEqual(CleaningColor.allCases, [.black, .white, .red, .green, .blue])
    }

    func testLabels() {
        XCTAssertEqual(CleaningColor.black.label, "Black")
        XCTAssertEqual(CleaningColor.white.label, "White")
        XCTAssertEqual(CleaningColor.red.label, "Red")
        XCTAssertEqual(CleaningColor.green.label, "Green")
        XCTAssertEqual(CleaningColor.blue.label, "Blue")
    }
}

// MARK: - Time formatting

final class FormatTimeTests: XCTestCase {
    func testZero() {
        XCTAssertEqual(formatCleaningTime(0), "0:00")
    }

    func testSingleDigitSeconds() {
        XCTAssertEqual(formatCleaningTime(5), "0:05")
    }

    func testDoubleDigitSeconds() {
        XCTAssertEqual(formatCleaningTime(42), "0:42")
    }

    func testExactMinute() {
        XCTAssertEqual(formatCleaningTime(60), "1:00")
    }

    func testMinutesAndSeconds() {
        XCTAssertEqual(formatCleaningTime(125), "2:05")
    }

    func testLargeValue() {
        XCTAssertEqual(formatCleaningTime(3661), "61:01")
    }

    func testFractionalSeconds() {
        XCTAssertEqual(formatCleaningTime(90.7), "1:30")
    }
}

// MARK: - AppState

final class AppStateTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let state = AppState()
        XCTAssertFalse(state.isCleaning)
        XCTAssertEqual(state.currentColor, .black)
        XCTAssertEqual(state.elapsedTime, 0)
        XCTAssertEqual(state.unlockProgress, 0)
    }

    @MainActor
    func testCycleColorForward() {
        let state = AppState()
        XCTAssertEqual(state.currentColor, .black)

        state.cycleColor()
        XCTAssertEqual(state.currentColor, .white)

        state.cycleColor()
        XCTAssertEqual(state.currentColor, .red)

        state.cycleColor()
        XCTAssertEqual(state.currentColor, .green)

        state.cycleColor()
        XCTAssertEqual(state.currentColor, .blue)
    }

    @MainActor
    func testCycleColorWraps() {
        let state = AppState()
        state.currentColor = .blue
        state.cycleColor()
        XCTAssertEqual(state.currentColor, .black)
    }

    @MainActor
    func testCycleFullLoop() {
        let state = AppState()
        let initial = state.currentColor
        for _ in 0..<CleaningColor.allCases.count {
            state.cycleColor()
        }
        XCTAssertEqual(state.currentColor, initial)
    }
}
