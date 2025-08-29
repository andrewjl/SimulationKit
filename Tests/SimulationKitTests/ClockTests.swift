//
//  ClockTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class ClockTests: XCTestCase {
    func testClock() throws {
        let clock = Clock()
        XCTAssertEqual(clock.current().time, Clock.startingTime)

        let tick = clock.next()
        XCTAssertEqual(tick.time, Clock.startingTime)

        XCTAssertEqual(clock.current().time, Clock.startingTime + 1)

        let nextTick = clock.next()
        XCTAssertEqual(nextTick.time, 1)
    }

    func testClockReset() throws {
        let clock = Clock()

        let _ = clock.next()

        clock.reset()

        let resetTick = clock.next()
        XCTAssertEqual(
            resetTick.time,
            Clock.startingTime
        )
    }
}
