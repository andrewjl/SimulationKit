//
//  SimulationTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class SimulationTests: XCTestCase {
    func testSingleRunSteps() throws {
        var steps: [Step] = []

        let ledgersCount = 1

        let ledgerID = UUID().uuidString

        let model = Model.makeModel(
            duration: 3,
            plannedEvents: [
                Capture(
                    entity: Simulation.Event.createEmptyLedger(
                        ledgerID: ledgerID
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .createAsset(
                            name: "",
                            accountID: "1"
                        ),
                        ledgerID: ledgerID
                    ),
                    timestamp: 0
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .postAsset(
                            transaction: .debited(by: 400.0),
                            accountID: "1"
                        ),
                        ledgerID: ledgerID
                    ),
                    timestamp: 0
                )
            ]
        )
        let simulation = Simulation.make(from: model)
        let clock = Clock()
        let tick = clock.next()
        steps.append(
            try simulation.start(tick: tick)
        )

        XCTAssertEqual(steps[0].currentPeriod, 0)
        XCTAssertEqual(steps[0].totalPeriods, model.duration)
        XCTAssertEqual(steps[0].capture.entity.state.ledgers.count, 1)

        XCTAssertEqual(
            steps[0].capture.entity.state.ledgers.first?.currentBalance(),
            400.0
        )

        XCTAssertEqual(clock.time, 1)

        steps.append(
            try simulation.tick(clock.next())
        )

        XCTAssertEqual(steps[1].currentPeriod, 1)
        XCTAssertEqual(steps[1].totalPeriods, model.duration)
        XCTAssertEqual(steps[1].capture.entity.state.ledgers.count, ledgersCount)

        XCTAssertEqual(
            steps[1].capture.entity.state.ledgers.first?.currentBalance(),
            400.0
        )

        XCTAssertEqual(clock.time, 2)

        steps.append(
            try simulation.tick(clock.next())
        )

        XCTAssertEqual(steps[2].currentPeriod, 2)
        XCTAssertEqual(steps[2].totalPeriods, model.duration)
        XCTAssertFalse(steps[2].isFinal)
        XCTAssertEqual(steps[2].capture.entity.state.ledgers.count, ledgersCount)

        XCTAssertEqual(
            steps[2].capture.entity.state.ledgers.first?.currentBalance(),
            400.0
        )

        XCTAssertEqual(clock.time, 3)

        steps.append(
            try simulation.tick(clock.next())
        )

        XCTAssertTrue(steps[3].isFinal)

        XCTAssertEqual(
            simulation.executionMode,
            .completed(
                Capture(
                    entity: steps[3].capture.entity.state,
                    timestamp: 3
                )
            )
        )
    }

    func testClock() throws {
        let model = Model.makeModel(duration: 2)
        let simulation = Simulation.make(from: model)
        let clock = Clock()

        XCTAssertEqual(
            clock.time,
            Clock.startingTime
        )

        let _ = try simulation.start(tick: clock.next())

        XCTAssertEqual(
            clock.time,
            1
        )

        let _ = try simulation.tick(clock.next())

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

        let model = Model.makeModel(
            duration: 3,
            plannedEvents: [
                Capture(
                    entity: Simulation.Event.createEmptyLedger(ledgerID: ledgerIDs[0]),
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
                            transaction: .debited(by: 150.0),
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
                            transaction: .debited(by: 150.0),
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
                        ledgerID: ledgerIDs[0]
                    ),
                    timestamp: 3
                ),
                Capture(
                    entity: Simulation.Event.ledgerEvent(
                        event: .postAsset(
                            transaction: .debited(by: 150.0),
                            accountID: "3"
                        ),
                        ledgerID: ledgerIDs[0]
                    ),
                    timestamp: 3
                )
            ]
        )

        let simulation = Simulation.make(from: model)
        let clock = Clock()

        let _ = try simulation.start(tick: clock.next())
        _ = try simulation.tick(clock.next())
        _ = try simulation.tick(clock.next())

        XCTAssertEqual(
            clock.time,
            3
        )

        let elapsedThirdPeriod = try simulation.tick(clock.next())

        XCTAssertEqual(
            clock.time,
            4
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
                entity: Simulation.Event.ledgerEvent(
                    event: .createAsset(
                        name: "",
                        accountID: "1"
                    ),
                    ledgerID: "1"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postAsset(
                        transaction: .debited(by: 100.0),
                        accountID: "1"
                    ),
                    ledgerID: "1"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createAsset(
                        name: "",
                        accountID: "2"
                    ),
                    ledgerID: "2"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postAsset(
                        transaction: .debited(by: 100.0),
                        accountID: "2"
                    ),
                    ledgerID: "2"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createAsset(
                        name: "",
                        accountID: "3"
                    ),
                    ledgerID: "3"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postAsset(
                        transaction: .debited(by: 100.0),
                        accountID: "3"
                    ),
                    ledgerID: "3"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createAsset(
                        name: "",
                        accountID: "4"
                    ),
                    ledgerID: "4"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postAsset(
                        transaction: .debited(by: 100.0),
                        accountID: "4"
                    ),
                    ledgerID: "4"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createAsset(
                        name: "",
                        accountID: "5"
                    ),
                    ledgerID: "5"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postAsset(
                        transaction: .debited(by: 100.0),
                        accountID: "5"
                    ),
                    ledgerID: "5"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createAsset(
                        name: "",
                        accountID: "6"
                    ),
                    ledgerID: "6"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postAsset(
                        transaction: .debited(by: 100.0),
                        accountID: "6"
                    ),
                    ledgerID: "6"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createLiability(
                        name: "",
                        accountID: "7"
                    ),
                    ledgerID: "1"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postLiability(
                        transaction: .credited(by: 100.0),
                        accountID: "7"
                    ),
                    ledgerID: "1"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createLiability(
                        name: "",
                        accountID: "8"
                    ),
                    ledgerID: "2"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postLiability(
                        transaction: .credited(by: 100.0),
                        accountID: "8"
                    ),
                    ledgerID: "2"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createLiability(
                        name: "",
                        accountID: "9"
                    ),
                    ledgerID: "3"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postLiability(
                        transaction: .credited(by: 100.0),
                        accountID: "9"
                    ),
                    ledgerID: "3"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createLiability(
                        name: "",
                        accountID: "9"
                    ),
                    ledgerID: "4"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postLiability(
                        transaction: .credited(by: 100.0),
                        accountID: "9"
                    ),
                    ledgerID: "4"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createLiability(
                        name: "",
                        accountID: "10"
                    ),
                    ledgerID: "5"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postLiability(
                        transaction: .credited(by: 100.0),
                        accountID: "10"
                    ),
                    ledgerID: "5"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .createLiability(
                        name: "",
                        accountID: "11"
                    ),
                    ledgerID: "6"
                ),
                timestamp: 0
            ),
            Capture(
                entity: Simulation.Event.ledgerEvent(
                    event: .postLiability(
                        transaction: .credited(by: 100.0),
                        accountID: "11"
                    ),
                    ledgerID: "6"
                ),
                timestamp: 0
            )
        ]

        let model = Model(
            duration: 1,
            plannedEvents: plannedEvents
        )

        let initialEvents = model.initialEvents()

        let assetEvents: [Simulation.Event] = try XCTUnwrap(
            initialEvents.compactMap {
                guard case Simulation.Event.ledgerEvent(event: let event, ledgerID: _) = $0 else {
                    return nil
                }

                guard case Ledger.Event.createAsset(name: _, accountID: _ ) = event else {
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
                guard case Simulation.Event.ledgerEvent(event: let event, ledgerID: _) = $0 else {
                    return nil
                }

                guard case Ledger.Event.createLiability(name: _, accountID: _ ) = event else {
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
            banks: [
                Bank(
                    loanRateSpread: 5
                ),
            ],
            centralBank: CentralBank(
                riskFreeRate: 4,
                eventCaptures: []
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
            event: Simulation.Event.ledgerEvent(
                event: .createAsset(
                    name: "",
                    accountID: "1"
                ),
                ledgerID: ledgerID
            ),
            period: 1
        ).applying(
            event: Simulation.Event.ledgerEvent(
                event: .postAsset(
                    transaction: .debited(by: 100.0),
                    accountID: "1"
                ),
                ledgerID: ledgerID
            ),
            period: 1
        )

        let secondSuccessorStateLedger = try XCTUnwrap(
            secondSuccessorState.ledgers.first,
            "Expected at least one extant ledger"
        )

        XCTAssertEqual(
            secondSuccessorStateLedger.assets.count,
            1,
            "Expected one assets ledger"
        )

        let secondBankLedgerID = UUID().uuidString

        let thirdSuccessorState = secondSuccessorState.applying(
            event: .createBank(
                startingCapital: 10_000,
                loanRateSpread: 1,
                bankLedgerID: secondBankLedgerID
            ),
            period: 2
        )

        let newBank = try XCTUnwrap(
            thirdSuccessorState.banks.last
        )

        XCTAssertEqual(
            newBank.loanRateSpread,
            1
        )

        let fourthSuccessorState = thirdSuccessorState.applying(
            event: .centralBankEvent(
                event: .changeRiskFreeRate(
                    rate: 3
                )
            ),
            period: 3
        )

        XCTAssertNotEqual(
            thirdSuccessorState,
            fourthSuccessorState
        )
    }
}

