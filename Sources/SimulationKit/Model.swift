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

class ExecutionalModel {
    var ledger: Ledger
    var totalPeriods: UInt32

    init(
        ledger: Ledger,
        totalPeriods: UInt32
    ) {
        self.ledger = ledger
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
        ledger.assets.map {
            Ledger.Event.asset(
                transaction: Asset.Transaction.increasing(by: $0.currentBalance().decimalizedAdjustment(percentage: $0.rate)),
                id: $0.id
            )
        } + ledger.liabilities.map {
            Ledger.Event.liability(
                transaction: Liability.Transaction.increasing(by: $0.currentBalance().decimalizedAdjustment(percentage: $0.rate)),
                id: $0.id
            )
        }
    }
}

extension ExecutionalModel {
    static func makeExecutionalModel(model: Model) -> ExecutionalModel {
        let assets = (1...model.assetsCount).map {
            Asset(id: UInt($0), rate: model.rate, balance: model.initialAssetBalance)
        }

        let liabilities = (1...model.liabilitiesCount).map {
            Liability(id: UInt($0), rate: model.rate, balance: model.initialLiabilityBalance)
        }

        let ledger = Ledger(
            assets: assets,
            liabilities: liabilities
        )

        let execModel = ExecutionalModel(ledger: ledger, totalPeriods: model.duration)

        return execModel
    }
}

