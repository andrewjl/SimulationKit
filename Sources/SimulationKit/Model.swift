//
//  Model.swift
//  
//

import Foundation

class ConceptualModel {
    var initialAssetBalance: Decimal
    var initialLiabilityBalance: Decimal

    var duration: UInt32 = 7
    var plannedEvents: [Capture<Simulation.Event>]

    init(
        rate: UInt,
        initialAssetBalance: Decimal,
        initialLiabilityBalance: Decimal,
        assetsCount: Int = 2,
        liabilitiesCount: Int = 2,
        ledgersCount: Int = 3,
        plannedEvents: [Capture<Simulation.Event>] = []
    ) {
        self.initialAssetBalance = initialAssetBalance
        self.initialLiabilityBalance = initialLiabilityBalance

        let inferredCreationEvents = (1...ledgersCount)
            .reduce(
                [],
                { (part:[Simulation.Event], ledgerID: Int) in

                    let assetCreationEvents = (1...assetsCount).map { (_: Int) in
                        Simulation.Event.createAsset(balance: initialAssetBalance, ledgerID: UInt(ledgerID-1))
                    }

                    let liabilityCreationEvents = (1...liabilitiesCount).map { (_: Int) in
                        Simulation.Event.createLiability(balance: initialLiabilityBalance, ledgerID: UInt(ledgerID-1))
                    }

                    return part + assetCreationEvents + liabilityCreationEvents
                }
            )
            .map { Capture(entity: $0, timestamp: Clock.startingTime) }

        let inferredRiskFreeRateEvent = Capture(
            entity: Simulation.Event.changeRiskFreeRate(newRate: Int(rate)),
            timestamp: Clock.startingTime
        )

        self.plannedEvents = plannedEvents + inferredCreationEvents + [inferredRiskFreeRateEvent]
    }

    func initialEvents() -> [Simulation.Event] {
        return plannedEvents
            .filter({ $0.timestamp == Clock.startingTime })
            .map { $0.entity }
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

