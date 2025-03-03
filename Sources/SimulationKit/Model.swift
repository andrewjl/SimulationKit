//
//  Model.swift
//  
//

import Foundation

class ConceptualModel {
    var rate: UInt
    var initialAssetBalance: Decimal
    var initialLiabilityBalance: Decimal

    var ledgersCount: Int
    var assetsCount: Int = 2
    var liabilitiesCount: Int = 2

    var duration: UInt32 = 7

    init(
        rate: UInt,
        initialAssetBalance: Decimal,
        initialLiabilityBalance: Decimal,
        ledgersCount: Int = 3
    ) {
        self.rate = rate
        self.initialAssetBalance = initialAssetBalance
        self.initialLiabilityBalance = initialLiabilityBalance
        self.ledgersCount = ledgersCount
    }
}

//extension ConceptualModel {
//    class LedgerGenerator {
//        func generate() -> [Ledger] {
//            return []
//        }
//    }
//}

typealias Model = ConceptualModel

struct RiskFreeRate {
    var rate: Int
}

class Simulation {
    var ledgers: [Ledger]
    var riskFreeRate: RiskFreeRate
    var totalPeriods: UInt32

    init(
        ledgers: [Ledger],
        rate: RiskFreeRate,
        totalPeriods: UInt32
    ) {
        self.ledgers = ledgers
        self.riskFreeRate = rate
        self.totalPeriods = totalPeriods
    }

    func start(clock: Clock) -> Step {
        guard clock.time == Clock.startingTime else {
            fatalError("Can only start simulation once.")
        }

        let events: [[Ledger.Event]] = (0..<ledgers.count).map { (i: Int) in return [] as [Ledger.Event] }

        let _ = clock.next()

        return Step(
            ledgers: ledgers,
            events: events,
            currentPeriod: Clock.startingTime,
            totalPeriods: totalPeriods
        )
    }

    func tick(clock: Clock) -> Step {
        guard clock.time > Clock.startingTime else {
            fatalError("Simulation not started yet.")
        }

        let tick = clock.current()
        let step = successiveStep(tick: tick)
        let _ = clock.next()
        return step
    }

    func successiveStep(tick: Tick) -> Step {
        let events = ledgers.map { self.events(ledger: $0) }
        let nextLedgers: [Ledger] = ledgers.enumerated().map {
            return $0.element.tick(events: events[$0.offset])
        }
        ledgers = nextLedgers
        return Step(ledgers: ledgers, events: events, currentPeriod: tick.time, totalPeriods: totalPeriods)
    }

    func events(ledger: Ledger) -> [Ledger.Event] {
        let increaseAssetLedgerEvents = ledger.assets.map {
            Ledger.Event.asset(
                transaction: $0.increaseTransaction(by: UInt(self.riskFreeRate.rate)),
                id: $0.id,
                ledgerID: ledger.id
            )
        }
        let increaseLiabilityLedgerEvents = ledger.liabilities.map {
            Ledger.Event.liability(
                transaction: $0.increaseTransaction(by: UInt(self.riskFreeRate.rate)),
                id: $0.id,
                ledgerID: ledger.id
            )
        }

        return increaseAssetLedgerEvents + increaseLiabilityLedgerEvents
    }
}

extension Simulation {
    static func make(from model: Model) -> Simulation {
        let assets = (1...model.assetsCount).map {
            Asset(id: UInt($0), balance: model.initialAssetBalance)
        }

        let liabilities = (1...model.liabilitiesCount).map {
            Liability(id: UInt($0), balance: model.initialLiabilityBalance)
        }

        let ledgers = (1...model.ledgersCount).map {
            return Ledger(
                id: UInt($0),
                assets: assets,
                liabilities: liabilities
            )
        }

        let riskFreeRate = RiskFreeRate(rate: Int(model.rate))

        let execModel = Simulation(
            ledgers: ledgers,
            rate: riskFreeRate,
            totalPeriods: model.duration
        )

        return execModel
    }
}

