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

        let startingLedger = historian.reconstructedLedger(
            at: Clock.startingTime,
            for: run.handle
        )
        let initialModelLedger = Simulation.make(from: model).ledger
        XCTAssertEqual(startingLedger?.currentBalance(), initialModelLedger.currentBalance())
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

        let initialModelLedger = Simulation.make(from: model).ledger

        let assetEvents: [Ledger.Event] = initialModelLedger.assets.map { Ledger.Event.asset(transaction: $0.increaseTransaction(by: model.rate), id: $0.id) }
        let liabilityEvents: [Ledger.Event] = initialModelLedger.liabilities.map { Ledger.Event.liability(transaction: $0.increaseTransaction(by: model.rate), id: $0.id) }
        let firstPeriodEvents = assetEvents + liabilityEvents

        let successiveModelLedger = initialModelLedger.tick(
            events: firstPeriodEvents
        )

        let secondPeriodLedger = historian.reconstructedLedger(
            at: 2,
            for: run.handle
        )

        XCTAssertEqual(secondPeriodLedger?.currentBalance(), successiveModelLedger.currentBalance())
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

        let reconstructedLedger = historian.reconstructedLedger(
            at: model.duration,
            for: run.handle
        )

        XCTAssertEqual(run.finalLedger.entity.currentBalance(), reconstructedLedger?.currentBalance())
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

        XCTAssertTrue(historian.ledgers.isEmpty)
        XCTAssertTrue(historian.ledgerPoints.isEmpty)

        XCTAssertEqual(historian.records.count, 1)
    }
}
