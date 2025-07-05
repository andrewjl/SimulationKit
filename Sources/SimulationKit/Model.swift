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
    var plannedEvents: [Capture<Simulation.Event>]

    init(
        rate: UInt,
        initialAssetBalance: Decimal,
        initialLiabilityBalance: Decimal,
        ledgersCount: Int = 3,
        plannedEvents: [Capture<Simulation.Event>] = []
    ) {
        self.rate = rate
        self.initialAssetBalance = initialAssetBalance
        self.initialLiabilityBalance = initialLiabilityBalance
        self.ledgersCount = ledgersCount
        self.plannedEvents = plannedEvents
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
