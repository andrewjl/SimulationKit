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
        XCTAssertEqual(tick.time, 1)

        let nextTick = clock.next()
        XCTAssertEqual(nextTick.time, 2)

        clock.reset()

        let resetTick = clock.next()
        XCTAssertEqual(resetTick.time, 1)
    }

    func testSimulationSingleRunExecution() throws {
        let model = Model.makeModel()
        let simulation = ExecutionalModel.makeExecutionalModel(
            model: model
        )
        let clock = Clock()

        let step1 = simulation.tick(clock: clock)

        XCTAssertEqual(step1.currentPeriod, 1)
        XCTAssertEqual(step1.totalPeriods, model.duration)
        XCTAssertEqual(step1.ledger.currentBalance(), 400.0)

        XCTAssertEqual(clock.time, 2)

        let step2 = simulation.tick(clock: clock)

        XCTAssertEqual(step2.currentPeriod, 2)
        XCTAssertEqual(step2.totalPeriods, model.duration)
        XCTAssertEqual(step2.ledger.currentBalance(), 420.0)

        XCTAssertEqual(clock.time, 3)

        let step3 = simulation.tick(clock: clock)

        XCTAssertEqual(step3.currentPeriod, 3)
        XCTAssertEqual(step3.totalPeriods, model.duration)
        XCTAssertEqual(step3.ledger.currentBalance(), 441.0)

        XCTAssertEqual(clock.time, 4)
    }

    func testSimulationMultipleRunExecution() {
        let model = Model.makeModel()
        let simulator = Simulator()
        let runs = simulator.execute(model: model, runsCount: 5)
        XCTAssertEqual(runs.count, 5)
    }
}
