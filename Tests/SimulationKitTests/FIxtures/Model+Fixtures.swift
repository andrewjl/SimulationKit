//
//  Model+Fixtures.swift
//  
//

import Foundation
@testable import SimulationKit

extension Model {
    static func makeModel(
        assetsCount: Int = 2,
        ledgersCount: Int = 1,
        plannedEvents: [Capture<Simulation.Event>] = []
    ) -> Model {
        return Model(
            rate: 5,
            initialAssetBalance: 300,
            initialLiabilityBalance: 100,
            assetsCount: assetsCount,
            ledgersCount: ledgersCount,
            plannedEvents: plannedEvents
        )
    }
}
