//
//  SimulationTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class SimulationTests: XCTestCase {
    func testSingleRunSteps() throws {
        let ledgersCount = 1

        let ledgerID = UUID().uuidString

        let model = Model.makeModel(
            plannedEvents: [
                Capture(
                    entity: Simulation.Event.createEmptyLedger(
                        ledgerID: ledgerID
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.createAsset(
                        balance: 400.0,
                        ledgerID: ledgerID
                    ),
                    timestamp: 0
                ),
            ]
        )
        let simulation = Simulation.make(from: model)
        let clock = Clock()
        let tick = clock.next()
        let initial = simulation.start(tick: tick)

        XCTAssertEqual(initial.currentPeriod, 0)
        XCTAssertEqual(initial.totalPeriods, model.duration)
        XCTAssertEqual(initial.capture.entity.state.ledgers.count, 1)

        XCTAssertEqual(
            initial.capture.entity.state.ledgers.first?.currentBalance(),
            400.0
        )

        XCTAssertEqual(clock.time, 1)

        let step1 = simulation.tick(clock.next())

        XCTAssertEqual(step1.currentPeriod, 1)
        XCTAssertEqual(step1.totalPeriods, model.duration)
        XCTAssertEqual(step1.capture.entity.state.ledgers.count, ledgersCount)

        XCTAssertEqual(
            step1.capture.entity.state.ledgers.first?.currentBalance(),
            400.0
        )

        XCTAssertEqual(clock.time, 2)

        let step2 = simulation.tick(clock.next())

        XCTAssertEqual(step2.currentPeriod, 2)
        XCTAssertEqual(step2.totalPeriods, model.duration)
        XCTAssertEqual(step2.capture.entity.state.ledgers.count, ledgersCount)

        XCTAssertEqual(
            step2.capture.entity.state.ledgers.first?.currentBalance(),
            400.0
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
        let ledgerIDs = [
            UUID().uuidString
        ]

        let initialAssetsCount:Int = 2

        let createAssetEvent = Simulation.Event.createAsset(
            balance: 150.0,
            ledgerID: ledgerIDs[0]
        )

        let model = Model.makeModel(
            plannedEvents: [
                Capture(
                    entity: Simulation.Event.createEmptyLedger(ledgerID: ledgerIDs[0]),
                    timestamp: 0
                ),
                Capture(
                    entity: createAssetEvent,
                    timestamp: 0
                ),
                Capture(
                    entity: createAssetEvent,
                    timestamp: 0
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
        let elapsedFirstPeriod = simulation.tick(clock.next())
        let elapsedSecondPeriod = simulation.tick(clock.next())

        XCTAssertEqual(
            clock.time,
            3
        )

        let elapsedThirdPeriod = simulation.tick(clock.next())

        XCTAssertEqual(
            clock.time,
            4
        )

        XCTAssertTrue(
            elapsedThirdPeriod.capture.entity.events.contains(createAssetEvent)
        )

        let finalLedger = try XCTUnwrap(
            elapsedThirdPeriod
                .capture
                .entity
                .state
                .ledgers
                .first(
                    where: { $0.id == ledgerIDs[0] }
                ),
            "Missing initial ledger in the third period snapshot"
        )

        XCTAssertEqual(
            finalLedger.assets.count,
            initialAssetsCount + 1
        )
    }

    func testStateGenerator() throws {
        let initialEvents: [Simulation.Event] = [
            Simulation.Event.createAsset(balance: 100.0, ledgerID: "0"),
            Simulation.Event.createLiability(balance: 100.0, ledgerID: "0")
        ]

        let state = StateGenerator.generate(from: initialEvents)

        XCTAssertEqual(
            state.ledgers.count,
            1
        )

        let ledger = try XCTUnwrap(
            state.ledgers.first(where: { $0.id == "0" })
        )

        XCTAssertEqual(
            ledger.currentBalance(),
            0.0
        )
    }

    func testModel() throws {

        let plannedEvents = [
            Capture(
                entity: Simulation.Event.createEmptyLedger(ledgerID: "1"),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createEmptyLedger(ledgerID: "2"),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createEmptyLedger(ledgerID: "3"),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createEmptyLedger(ledgerID: "4"),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createEmptyLedger(ledgerID: "5"),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createEmptyLedger(ledgerID: "6"),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createAsset(
                    balance: 100.0,
                    ledgerID: "1"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createAsset(
                    balance: 100.0,
                    ledgerID: "2"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createAsset(
                    balance: 100.0,
                    ledgerID: "3"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createAsset(
                    balance: 100.0,
                    ledgerID: "4"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createAsset(
                    balance: 100.0,
                    ledgerID: "5"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createAsset(
                    balance: 100.0,
                    ledgerID: "6"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createLiability(
                    balance: 100.0,
                    ledgerID: "1"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createLiability(
                    balance: 100.0,
                    ledgerID: "2"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createLiability(
                    balance: 100.0,
                    ledgerID: "3"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createLiability(
                    balance: 100.0,
                    ledgerID: "4"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createLiability(
                    balance: 100.0,
                    ledgerID: "5"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.createLiability(
                    balance: 100.0,
                    ledgerID: "6"
                ),
                timestamp: 0
            )
        ]

        let model = Model(
            plannedEvents: plannedEvents
        )

        let initialEvents = model.initialEvents()

        let assetEvents: [Simulation.Event] = try XCTUnwrap(
            initialEvents.compactMap {
                guard case Simulation.Event.createAsset = $0 else {
                    return nil
                }

                return $0
            }
        )

        XCTAssertEqual(
            assetEvents.count,
            6,
            "The models initial events should contain 1 asset creation event for each ledger."
        )

        let liabilityEvents: [Simulation.Event] = try XCTUnwrap(
            initialEvents.compactMap {
                guard case Simulation.Event.createLiability = $0 else {
                    return nil
                }

                return $0
            }
        )

        XCTAssertEqual(
            liabilityEvents.count,
            6,
            "The models initial events should contain 1 liability creation event for each ledger."
        )
    }

    func testSimulationState() throws {
        let state = Simulation.State(
            ledgers: [],
            bank: Bank(
                riskFreeRate: 4
            )
        )

        let ledgerID = UUID().uuidString

        let firstSuccessorState = state.applying(
            event: .createEmptyLedger(
                ledgerID: ledgerID
            ),
            period: 0
        )

        let firstSuccessorStateLedger = try XCTUnwrap(
            firstSuccessorState.ledgers.first,
            "Expected at least one extant ledger after create empty ledger event"
        )

        XCTAssertTrue(
            firstSuccessorStateLedger.assets.count == 0,
            "Expected no assets in empty ledger"
        )

        let secondSuccessorState = firstSuccessorState.applying(
            event: .createAsset(
                balance: 100.0,
                ledgerID: ledgerID
            ),
            period: 1
        )

        let secondSuccessorStateLedger = try XCTUnwrap(
            secondSuccessorState.ledgers.first,
            "Expected at least one extant ledger"
        )

        XCTAssertTrue(
            secondSuccessorStateLedger.assets.count == 1,
            "Expected one assets ledger"
        )
    }
}

