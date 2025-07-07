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
        let tick = clock.next()
        let initial = simulation.start(tick: tick)

        XCTAssertEqual(initial.currentPeriod, 0)
        XCTAssertEqual(initial.totalPeriods, model.duration)
        XCTAssertEqual(initial.capture.entity.state.ledgers.count, model.ledgersCount)

        XCTAssertEqual(
            initial.capture.entity.state.ledgers.first?.currentBalance(),
            400.0
        )

        XCTAssertEqual(clock.time, 1)

        let step1 = simulation.tick(clock.next())

        XCTAssertEqual(step1.currentPeriod, 1)
        XCTAssertEqual(step1.totalPeriods, model.duration)
        XCTAssertEqual(step1.capture.entity.state.ledgers.count, model.ledgersCount)

        XCTAssertEqual(
            step1.capture.entity.state.ledgers.first?.currentBalance(),
            420.0
        )

        XCTAssertEqual(clock.time, 2)

        let step2 = simulation.tick(clock.next())

        XCTAssertEqual(step2.currentPeriod, 2)
        XCTAssertEqual(step2.totalPeriods, model.duration)
        XCTAssertEqual(step2.capture.entity.state.ledgers.count, model.ledgersCount)

        XCTAssertEqual(
            step2.capture.entity.state.ledgers.first?.currentBalance(),
            441.0
        )

        XCTAssertEqual(clock.time, 3)
    }

    func testClock() throws {
        let model = Model.makeModel()
        let simulation = Simulation.make(from: model)
        let clock = Clock()

        XCTAssertEqual(
            clock.time,
            Clock.startingTime
        )

        let _ = simulation.start(tick: clock.next())

        XCTAssertEqual(
            clock.time,
            1
        )

        let _ = simulation.tick(clock.next())

        XCTAssertEqual(
            clock.time,
            2
        )
    }

    func testPlannedEvents() throws {
        let riskFreeRatePlannedEvent = Simulation.Event.changeRiskFreeRate(newRate: 7)
        let createAssetEvent = Simulation.Event.createAsset(balance: 150.0, ledgerID: 0)
        let model = Model.makeModel(
            plannedEvents: [
                Capture(
                    entity: riskFreeRatePlannedEvent,
                    timestamp: 2
                ),
                Capture(
                    entity: createAssetEvent,
                    timestamp: 3
                )
            ]
        )
        let simulation = Simulation.make(from: model)
        let clock = Clock()

        let _ = simulation.start(tick: clock.next())
        let _ = simulation.tick(clock.next())
        let elapsedSecondPeriod = simulation.tick(clock.next())

        XCTAssertEqual(
            clock.time,
            3
        )

        XCTAssertTrue(
            elapsedSecondPeriod.capture.entity.events.contains(riskFreeRatePlannedEvent)
        )

        let elapsedThirdPeriod = simulation.tick(clock.next())

        XCTAssertEqual(
            clock.time,
            4
        )

        XCTAssertTrue(
            elapsedThirdPeriod.capture.entity.events.contains(createAssetEvent)
        )

        XCTAssertEqual(
            elapsedThirdPeriod.capture.entity.state.ledgers.first(where: { $0.id == 0 })?.assets.count,
            model.assetsCount + 1
        )
    }
}

