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

        let startingLedgers = historian.reconstructedLedgers(
            at: Clock.startingTime,
            for: run.handle
        )
        let initialModelLedgers = Simulation.make(from: model).ledgers
        XCTAssertEqual(startingLedgers?.currentBalances(), initialModelLedgers.currentBalances())
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

        let initialModelLedgers = Simulation.make(from: model).ledgers

        let assetEvents: [[Ledger.Event]] = initialModelLedgers
            .map { (ledger: Ledger) -> [Ledger.Event] in
                let ledgerID = ledger.id
                return ledger.assets.map {
                    Ledger.Event.asset(transaction: $0.increaseTransaction(by: model.rate), id: $0.id, ledgerID: ledgerID)
                }
            }


        let liabilityEvents: [[Ledger.Event]] = initialModelLedgers
            .map { (ledger: Ledger) -> [Ledger.Event] in
                let ledgerID = ledger.id
                return ledger.liabilities.map {
                    Ledger.Event.liability(transaction: $0.increaseTransaction(by: model.rate), id: $0.id, ledgerID: ledgerID)
                }
            }


        let initialEvents = (assetEvents + liabilityEvents).joined()

        let successiveModelLedgers: [Ledger] = initialModelLedgers.map { (ledger: Ledger) -> Ledger in
            return ledger.tick(events: initialEvents.filter { $0.ledgerID == ledger.id } )
        }

        let firstElapsedPeriodReconstruction = historian.reconstructedLedgers(
            at: 1,
            for: run.handle
        )

        XCTAssertEqual(
            firstElapsedPeriodReconstruction?.currentBalances(),
            successiveModelLedgers.currentBalances()
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

        let reconstructedLedgers = historian.reconstructedLedgers(
            at: model.duration,
            for: run.handle
        )

        XCTAssertEqual(
            reconstructedLedgers?.currentBalances(),
            run.finalLedgers.entity.currentBalances()
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
