//
//  SimulationTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class SimulationTests: XCTestCase {
    func testSingleRunSteps() throws {
        let model = Model.makeModel()
        let simulation = Simulation.make(from: model)
        let clock = Clock()

        let initial = simulation.start(clock: clock)

        XCTAssertEqual(initial.currentPeriod, 0)
        XCTAssertEqual(initial.totalPeriods, model.duration)
        XCTAssertEqual(initial.capture.entity.state.ledgers.count, model.ledgersCount)

        XCTAssertEqual(
            initial.capture.entity.state.ledgers.first?.currentBalance(),
            400.0
        )

        XCTAssertEqual(clock.time, 1)

        let step1 = simulation.tick(clock: clock)

        XCTAssertEqual(step1.currentPeriod, 1)
        XCTAssertEqual(step1.totalPeriods, model.duration)
        XCTAssertEqual(step1.capture.entity.state.ledgers.count, model.ledgersCount)

        XCTAssertEqual(
            step1.capture.entity.state.ledgers.first?.currentBalance(),
            420.0
        )

        XCTAssertEqual(clock.time, 2)

        let step2 = simulation.tick(clock: clock)

        XCTAssertEqual(step2.currentPeriod, 2)
        XCTAssertEqual(step2.totalPeriods, model.duration)
        XCTAssertEqual(step2.capture.entity.state.ledgers.count, model.ledgersCount)

        XCTAssertEqual(
            step2.capture.entity.state.ledgers.first?.currentBalance(),
            441.0
        )

        XCTAssertEqual(clock.time, 3)
    }

    func testPlannedEvents() throws {
        let plannedEvent = Simulation.Event.changeRiskFreeRate(newRate: 7)
        let model = Model.makeModel(
            plannedEvents: [
                Capture(
                    entity: plannedEvent,
                    timestamp: 2
                )
            ]
        )
        let simulation = Simulation.make(from: model)
        let clock = Clock()

        let _ = simulation.start(clock: clock)
        let _ = simulation.tick(clock: clock)
        let elapsedSecondPeriod = simulation.tick(clock: clock)

        XCTAssertEqual(
            clock.time,
            3
        )

        XCTAssertTrue(elapsedSecondPeriod.capture.entity.events.contains(plannedEvent))
    }
}

