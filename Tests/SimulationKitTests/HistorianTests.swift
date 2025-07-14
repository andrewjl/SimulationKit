//
//  HistorianTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class HistorianTests: XCTestCase {
    func testOutputFirst() throws {
        let historian = Historian()
        let simulator = Simulator(historian: historian)
        let model = Model.makeModel()

        let runs = simulator.execute(model: model)
        let run = try XCTUnwrap(runs.first)

        XCTAssertEqual(
            run.totalPeriods,
            model.duration,
            "Simulation run duration should be the same as specified in the model"
        )

        // TODO: Check needed for model state
    }

    func testOutputSecond() throws {
        let historian = Historian()
        let simulator = Simulator(historian: historian)
        let model = Model.makeModel()

        let runs = simulator.execute(model: model)
        let run = try XCTUnwrap(runs.first)

        XCTAssertEqual(
            run.totalPeriods,
            model.duration,
            "Simulation run duration should be the same as specified in the model"
        )

        // TODO: Check needed for model state
    }

    func testOutputLast() throws {
        let historian = Historian()
        let simulator = Simulator(historian: historian)
        let model = Model.makeModel()

        let runs = simulator.execute(model: model)
        let run = try XCTUnwrap(runs.first)

        XCTAssertEqual(
            run.totalPeriods,
            model.duration,
            "Simulation run duration should be the same as specified in the model"
        )

        let reconstructed = historian.reconstructedLedgers(
            at: model.duration,
            for: run.handle
        )

        XCTAssertEqual(
            reconstructed?.ledgers.currentBalances(),
            run.finalState.ledgers.currentBalances()
        )
    }

    func testRecordAccess() throws {
        let historian = Historian()
        let simulator = Simulator(historian: historian)
        let model = Model.makeModel()

        simulator.execute(model: model)

        XCTAssertEqual(historian.records.count, 1)
        let record = try XCTUnwrap(historian.records.first)

        XCTAssertEqual(record.period, model.duration)
    }

    func testReset() throws {
        let historian = Historian()
        let simulator = Simulator(historian: historian)
        let model = Model.makeModel()

        simulator.execute(model: model)

        XCTAssertTrue(historian.captures.isEmpty)
        XCTAssertEqual(historian.records.count, 1)
    }
}
