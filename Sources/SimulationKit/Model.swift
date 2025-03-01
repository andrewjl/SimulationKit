//
//  Model.swift
//  
//

import Foundation

class ConceptualModel {
    var rate: UInt
    var initialAssetBalance: Decimal
    var initialLiabilityBalance: Decimal

    var assetsCount: Int = 2
    var liabilitiesCount: Int = 2

    var duration: UInt32 = 7

    init(
        rate: UInt,
        initialAssetBalance: Decimal,
        initialLiabilityBalance: Decimal
    ) {
        self.rate = rate
        self.initialAssetBalance = initialAssetBalance
        self.initialLiabilityBalance = initialLiabilityBalance
    }
}

typealias Model = ConceptualModel

struct RiskFreeRate {
    var rate: Int
}

class ExecutionalModel {
    var ledger: Ledger
    var riskFreeRate: RiskFreeRate
    var totalPeriods: UInt32

    init(
        ledger: Ledger,
        rate: RiskFreeRate,
        totalPeriods: UInt32
    ) {
        self.ledger = ledger
        self.riskFreeRate = rate
        self.totalPeriods = totalPeriods
    }

    func tick(clock: Clock) -> Step {
        let tick = clock.next()
        if tick.time > Clock.startingTime {
            let events = events(ledger: ledger)
            ledger = ledger.tick(events: events)
            return Step(ledger: ledger, events: events, currentPeriod: tick.time, totalPeriods: totalPeriods)
        } else {
            return Step(ledger: ledger, events: [], currentPeriod: tick.time, totalPeriods: totalPeriods)
        }
    }

    func events(ledger: Ledger) -> [Ledger.Event] {
        let increaseAssetLedgerEvents = ledger.assets.map {
            Ledger.Event.asset(transaction: $0.increaseTransaction(by: UInt(self.riskFreeRate.rate)), id: $0.id)
        }
        let increaseLiabilityLedgerEvents = ledger.liabilities.map {
            Ledger.Event.liability(transaction: $0.increaseTransaction(by: UInt(self.riskFreeRate.rate)), id: $0.id)
        }

        return increaseAssetLedgerEvents + increaseLiabilityLedgerEvents
    }
}

extension ExecutionalModel {
    static func makeExecutionalModel(model: Model) -> ExecutionalModel {
        let assets = (1...model.assetsCount).map {
            Asset(id: UInt($0), balance: model.initialAssetBalance)
        }

        let liabilities = (1...model.liabilitiesCount).map {
            Liability(id: UInt($0), balance: model.initialLiabilityBalance)
        }

        let ledger = Ledger(
            assets: assets,
            liabilities: liabilities
        )
        let riskFreeRate = RiskFreeRate(rate: Int(model.rate))

        let execModel = ExecutionalModel(
            ledger: ledger,
            rate: riskFreeRate,
            totalPeriods: model.duration
        )

        return execModel
    }
}

