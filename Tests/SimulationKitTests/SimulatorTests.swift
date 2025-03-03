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

    func testRun() throws {
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
    }

    func testSimulationSingleRunExecution() throws {
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

    func testSimulationMultipleRunExecution() {
        let model = Model.makeModel()
        let simulator = Simulator()
        let runs = simulator.execute(model: model, runsCount: 5)
        XCTAssertEqual(runs.count, 5)
    }
}
