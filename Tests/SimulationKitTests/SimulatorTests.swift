//
//  SimulatorTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class SimulatorTests: XCTestCase {
    func testSimulation() throws {
        let model = Model(
            rate: 5,
            initialAssetBalance: 300,
            initialLiabilityBalance: 100
        )
        let simulator = Simulator()
        let run = simulator.execute(model: model)
        print(run)
    }

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

    func testSingleRun() throws {
        let model = Model(
            rate: 5,
            initialAssetBalance: 300,
            initialLiabilityBalance: 100,
            ledgersCount: 2
        )
        let simulator = Simulator()
        let runs = simulator.execute(model: model)

        let run = try XCTUnwrap(runs.first)

        XCTAssertEqual(
            run.finalState.ledgers.count,
            model.ledgersCount
        )
        XCTAssertEqual(
            run.totalPeriods,
            model.duration
        )
    }

    func testMultipleRuns() {
        let model = Model.makeModel()
        let simulator = Simulator()
        let runs = simulator.execute(model: model, runsCount: 5)
        XCTAssertEqual(runs.count, 5)

        for run in runs {
            XCTAssertEqual(
                run.finalState.ledgers.count,
                model.ledgersCount
            )
            XCTAssertEqual(
                run.totalPeriods,
                model.duration
            )
        }
    }
}
