//
//  SimulationTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class SimulationTests: XCTestCase {
    func testSingleRunSteps() throws {
        let ledgersCount = 1
        let model = Model.makeModel(ledgersCount: ledgersCount)
        let simulation = Simulation.make(from: model)
        let clock = Clock()
        let tick = clock.next()
        let initial = simulation.start(tick: tick)

        XCTAssertEqual(initial.currentPeriod, 0)
        XCTAssertEqual(initial.totalPeriods, model.duration)
        XCTAssertEqual(initial.capture.entity.state.ledgers.count, ledgersCount)

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
            420.0
        )

        XCTAssertEqual(clock.time, 2)

        let step2 = simulation.tick(clock.next())

        XCTAssertEqual(step2.currentPeriod, 2)
        XCTAssertEqual(step2.totalPeriods, model.duration)
        XCTAssertEqual(step2.capture.entity.state.ledgers.count, ledgersCount)

        XCTAssertEqual(
            step2.capture.entity.state.ledgers.first?.currentBalance(),
            441.0
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
        let riskFreeRatePlannedEvent = Simulation.Event.changeRiskFreeRate(newRate: 7)
        let createAssetEvent = Simulation.Event.createAsset(balance: 150.0, ledgerID: 0)
        let initialAssetsCount = 2
        let model = Model.makeModel(
            assetsCount: initialAssetsCount,
            plannedEvents: [
                Capture(
                    entity: riskFreeRatePlannedEvent,
                    timestamp: 2
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
        let _ = simulation.tick(clock.next())
        let elapsedSecondPeriod = simulation.tick(clock.next())

        XCTAssertEqual(
            clock.time,
            3
        )

        XCTAssertTrue(
            elapsedSecondPeriod.capture.entity.events.contains(riskFreeRatePlannedEvent)
        )

        let elapsedThirdPeriod = simulation.tick(clock.next())

        XCTAssertEqual(
            clock.time,
            4
        )

        XCTAssertTrue(
            elapsedThirdPeriod.capture.entity.events.contains(createAssetEvent)
        )

        XCTAssertEqual(
            elapsedThirdPeriod.capture.entity.state.ledgers.first(where: { $0.id == 0 })?.assets.count,
            initialAssetsCount + 1
        )
    }

    func testStateGenerator() throws {
        let initialEvents: [Simulation.Event] = [
            Simulation.Event.changeRiskFreeRate(newRate: 7),
            Simulation.Event.createAsset(balance: 100.0, ledgerID: 0),
            Simulation.Event.createLiability(balance: 100.0, ledgerID: 0)
        ]

        let state = StateGenerator.generate(from: initialEvents)

        XCTAssertEqual(
            state.riskFreeRate.rate,
            7
        )
        XCTAssertEqual(
            state.ledgers.count,
            1
        )

        let ledger = try XCTUnwrap(
            state.ledgers.first(where: { $0.id == 0 })
        )

        XCTAssertEqual(
            ledger.currentBalance(),
            0.0
        )
    }

    func testModel() throws {
        let assetsCount = 1
        let liabilitiesCount = 1
        let ledgersCount = 6
        let model = Model(
            rate: 4,
            initialAssetBalance: 500.0,
            initialLiabilityBalance: 200.0,
            assetsCount: assetsCount,
            liabilitiesCount: liabilitiesCount,
            ledgersCount: ledgersCount,
            plannedEvents: [
                Capture(
                    entity: Simulation.Event.createEmptyLedger(ledgerID: 6),
                    timestamp: 0
                )
            ]
        )

        let initialEvents = model.initialEvents()

        XCTAssertEqual(
            initialEvents.count,
            14,
            "The models initial events should contain 1 rate change event, 1 event for each asset & liability assigned to a ledger, and 1 event for any empty ledgers."
        )

        let _: Simulation.Event = try XCTUnwrap(
            initialEvents.compactMap {
                guard case Simulation.Event.changeRiskFreeRate = $0 else {
                    return nil
                }

                return $0
            }
            .first
        )

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
            assetsCount * ledgersCount,
            "The models initial events should contain \(assetsCount) asset creation event for each ledger."
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
            liabilitiesCount * ledgersCount,
            "The models initial events should contain \(liabilitiesCount) liability creation event for each ledger."
        )
    }
}

