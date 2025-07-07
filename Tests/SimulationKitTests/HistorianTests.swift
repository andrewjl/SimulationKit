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

        let startingState = historian.reconstructedLedgers(
            at: Clock.startingTime,
            for: run.handle
        )

        Asset.autoincrementedID = 0
        Liability.autoincrementedID = 0
        Ledger.autoincrementedID = 0

        let initialModelState = Simulation.make(from: model).state
        XCTAssertEqual(
            startingState?.ledgers.map { $0.assets.map { $0.id } + $0.liabilities.map { $0.id } },
            initialModelState.ledgers.map { $0.assets.map { $0.id } + $0.liabilities.map { $0.id } }
        )
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

        let firstElapsedPeriodReconstruction = historian.reconstructedLedgers(
            at: 1,
            for: run.handle
        )

        Asset.autoincrementedID = 0
        Liability.autoincrementedID = 0
        Ledger.autoincrementedID = 0

        let simulation = Simulation.make(from: model)
        let initialState = simulation.state
        let successiveState = simulation.computedEvents(
            state: simulation.state
        )
            .reduce(initialState, { return $0.apply(event: $1) })

        XCTAssertEqual(
            firstElapsedPeriodReconstruction,
            successiveState
        )
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
