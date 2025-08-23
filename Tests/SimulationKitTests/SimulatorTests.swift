//
//  SimulatorTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class SimulatorTests: XCTestCase {
    func testSimulation() throws {
        let model = Model()
        let simulator = Simulator()
        let run = simulator.execute(model: model)
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
        let ledgersCount = 2
        let ledgerIDs = [
            UUID().uuidString,
            UUID().uuidString,
        ]
        let model = Model(
            plannedEvents: [
                Capture(
                    entity: Simulation.Event.createEmptyLedger(
                        ledgerID: ledgerIDs[0]
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.createEmptyLedger(
                        ledgerID: ledgerIDs[1]
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .createAsset(
                            name: "",
                            accountID: "1"
                        ),
                        ledgerID: ledgerIDs[0]
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .postAsset(
                            transaction: .debited(by: 200.0),
                            accountID: "1"
                        ),
                        ledgerID: ledgerIDs[0]
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .createAsset(
                            name: "",
                            accountID: "2"
                        ),
                        ledgerID: ledgerIDs[0]
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .postAsset(
                            transaction: .debited(by: 100.0),
                            accountID: "2"
                        ),
                        ledgerID: ledgerIDs[0]
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .createAsset(
                            name: "",
                            accountID: "3"
                        ),
                        ledgerID: ledgerIDs[1]
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .postAsset(
                            transaction: .debited(by: 200.0),
                            accountID: "3"
                        ),
                        ledgerID: ledgerIDs[1]
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .createLiability(
                            name: "",
                            accountID: "4"
                        ),
                        ledgerID: ledgerIDs[1]
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .postLiability(
                            transaction: .credited(by: 100.0),
                            accountID: "4"
                        ),
                        ledgerID: ledgerIDs[1]
                    ),
                    timestamp: 0
                )
            ]
        )
        let simulator = Simulator()
        let runs = simulator.execute(model: model)

        let run = try XCTUnwrap(runs.first)

        XCTAssertEqual(
            run.finalState.ledgers.count,
            ledgersCount
        )
        XCTAssertEqual(
            run.totalPeriods,
            model.duration
        )
    }

    func testMultipleRuns() {
        let ledgersCount = 1
        let model = Model.makeModel(
            plannedEvents: [
                Capture(
                    entity: Simulation.Event.createEmptyLedger(
                        ledgerID: UUID().uuidString
                    ),
                    timestamp: 0
                )
            ]
        )
        let simulator = Simulator()
        let runs = simulator.execute(model: model, runsCount: 5)
        XCTAssertEqual(runs.count, 5)

        for run in runs {
            XCTAssertEqual(
                run.finalState.ledgers.count,
                ledgersCount
            )
            XCTAssertEqual(
                run.totalPeriods,
                model.duration
            )
        }
    }
}
