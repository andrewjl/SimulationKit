//
//  ClockTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class ClockTests: XCTestCase {
    func testClock() throws {
        let clock = Clock()

        let tick = clock.next()
        XCTAssertEqual(tick.time, Clock.startingTime)

        let nextTick = clock.next()
        XCTAssertEqual(nextTick.time, 1)

        clock.reset()

        let resetTick = clock.next()
        XCTAssertEqual(resetTick.time, Clock.startingTime)
    }
}
