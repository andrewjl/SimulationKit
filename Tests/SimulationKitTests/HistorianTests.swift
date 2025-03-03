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
        let initialModelState = Simulation.make(from: model).state
        XCTAssertEqual(
            startingState,
            initialModelState
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

        let simulation = Simulation.make(from: model)

        let events = simulation.state.ledgers.map {
            simulation.events(ledger: $0)
        }
        .map {
            return Simulation.Event.ledgerTransactions(transactions: $0)
        }

        let initialState = Simulation.make(from: model).state
        let successiveState = events.reduce(initialState, { return $0.apply(event: $1) })

        let firstElapsedPeriodReconstruction = historian.reconstructedLedgers(
            at: 1,
            for: run.handle
        )

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
